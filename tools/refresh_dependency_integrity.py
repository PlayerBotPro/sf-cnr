"""Record source integrity for legacy packages with executable files on Windows.

sampctl 1.16's Git worktree check mistakes their Unix executable bits for local
changes. Its supported SHA-256 directory integrity avoids that mode comparison.
Always verify source bytes against the locked Git commit before recording hashes.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ('pawn-lang/samp-stdlib', 'pawn-lang/pawn-stdlib', 'pawn-lang/YSI-Includes')
EXTENSIONS = {'.inc', '.pwn', '.json', '.yaml', '.yml'}


def relevant(path):
    return not any(part.startswith('.') for part in path.parts) and path.suffix.lower() in EXTENSIONS


def main():
    if os.name != 'nt':
        raise RuntimeError('These integrity records use sampctl Windows path conventions. Run on Windows.')
    lock_path = ROOT / 'pawn.lock'
    lock = json.loads(lock_path.read_text(encoding='utf-8'))
    for package in PACKAGES:
        dependency = lock['dependencies']['github.com/' + package]
        directory = ROOT / 'dependencies' / dependency['repo']

        def git(*args):
            return subprocess.check_output(['git', '-C', str(directory), *args])

        if git('rev-parse', 'HEAD').decode().strip() != dependency['commit']:
            raise RuntimeError(f'{package}: checkout does not match pawn.lock')
        files = {}
        for entry in git('ls-tree', '-rz', dependency['commit']).split(b'\0'):
            if not entry:
                continue
            metadata, name = entry.split(b'\t', 1)
            path = Path(name.decode('utf-8'))
            if relevant(path):
                files[str(path)] = metadata.split()[2].decode('ascii')
        actual = {str(path.relative_to(directory)) for path in directory.rglob('*')
                  if path.is_file() and relevant(path.relative_to(directory))}
        if actual != files.keys():
            raise RuntimeError(f'{package}: source file list differs from its locked commit')
        digest = hashlib.sha256()
        for relative, blob in sorted(files.items()):
            content = git('cat-file', 'blob', blob)
            if (directory / relative).read_bytes() != content:
                raise RuntimeError(f'{package}: {relative} differs from its locked Git blob')
            digest.update(relative.encode('utf-8'))
            digest.update(content)
        dependency['integrity'] = 'sha256:' + digest.hexdigest()
        print(f'Verified locked source bytes: {package}')
    lock_path.write_text(json.dumps(lock, indent='\t') + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
