"""Rebuild SF-CNR and package the installed Windows runtime for deployment."""
import argparse
from datetime import datetime
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def runtime_files():
    """Use an allowlist so local logs, saves, sources and caches stay out."""
    files = {
        'samp-server.exe', 'samp-npc.exe', 'announce.exe', 'libmysql.dll',
        'server.cfg', 'gamemodes/sf-cnr.amx', 'npcmodes/secureguard.amx',
        'scriptfiles/SAfull.hmap', 'scriptfiles/SAmin.hmap',
        'start-server.cmd', 'stop-server.cmd', 'server-status.cmd', 'tools/server.py',
        'RUNNING.md', 'DATABASE_SETUP.md', 'DISTRIBUTING.md', 'LICENSE',
    }
    # Read only filenames; never print configuration values or embedded secrets.
    settings = {}
    for line in (ROOT / 'server.cfg').read_text(encoding='utf-8-sig').splitlines():
        parts = line.split('//', 1)[0].split()
        if parts:
            settings[parts[0]] = parts[1:]
    for key, values in settings.items():
        if re.fullmatch(r'gamemode\d+', key) and values:
            files.add(f'gamemodes/{values[0]}.amx')
        elif key == 'filterscripts':
            files.update(f'filterscripts/{name}.amx' for name in values)
        elif key == 'plugins':
            for name in values:
                if name.lower().endswith('.so'):
                    raise RuntimeError('This packager requires Windows plugins in server.cfg.')
                files.add(f'plugins/{name}' if name.lower().endswith('.dll')
                          else f'plugins/{name}.dll')
    # Include companion DLLs too (for example RouteConnectorPluginDLL.dll).
    files.update(path.relative_to(ROOT).as_posix()
                 for path in (ROOT / 'plugins').glob('*.dll'))
    files.update(f'npcmodes/recordings/SECURITYGUARD{i:02d}.rec' for i in range(10))
    files.add('npcmodes/recordings/SECURITYGUARD_IDLE.rec')
    for folder, pattern in [
        ('npcmodes/recordings', '*.rec'),
        ('scriptfiles/changelogs', '*'),
        ('scriptfiles/COD', '*'),
        ('gamemodes/irresistible/config/migrations/cnr', '*.sql'),
    ]:
        found = [path for path in (ROOT / folder).rglob(pattern) if path.is_file()]
        if not found:
            raise RuntimeError(f'Missing runtime assets: {folder}/{pattern}')
        files.update(path.relative_to(ROOT).as_posix() for path in found)
    for name in sorted(files):
        path = (ROOT / name).resolve()
        if not path.is_relative_to(ROOT):
            raise RuntimeError(f'Runtime path is outside the checkout: {name}')
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f'Missing or empty runtime file: {name}')
    return sorted(files)


def distribute(output=None):
    if not (ROOT / 'gamemodes/irresistible/config/database.pwn').is_file():
        raise RuntimeError('Configure database.pwn first; see DATABASE_SETUP.md.')
    for target in ('gamemode', 'npc'):
        print(f'Building {target}...', flush=True)
        subprocess.run(['sampctl', 'build', target], cwd=ROOT, check=True)
    files = runtime_files()
    destination = (Path(output).resolve() if output else ROOT / 'dist' /
                   f'sf-cnr-windows-{datetime.now():%Y%m%d-%H%M%S-%f}.zip')
    if destination.suffix.lower() != '.zip':
        raise RuntimeError('Output filename must end in .zip.')
    if destination.exists():
        raise RuntimeError(f'Output already exists: {destination}')
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Publish only after compression and CRC verification complete successfully.
    with tempfile.TemporaryDirectory(prefix='.pack-', dir=destination.parent) as staging:
        temporary = Path(staging) / 'server.zip'
        with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED,
                             compresslevel=6) as archive:
            for name in files:
                archive.write(ROOT / name, name)
            for folder in ('filterscripts/', '.runtime/'):
                archive.writestr(folder, '')
        with zipfile.ZipFile(temporary) as archive:
            bad = archive.testzip()
            if bad:
                raise RuntimeError(f'Archive verification failed: {bad}')
        temporary.rename(destination)
    print(f'Created: {destination}\n{len(files)} files, {destination.stat().st_size / 1048576:.1f} MiB')
    print('Private package: includes server.cfg and database credentials embedded in AMX.')
    print('Update instructions: DISTRIBUTING.md (also inside the ZIP).')
    return destination


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', help='Optional ZIP path; defaults to dist/sf-cnr-windows-<timestamp>.zip')
    args = parser.parse_args()
    try:
        distribute(args.output)
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError,
            zipfile.BadZipFile) as error:
        print(f'Error: {error}', file=sys.stderr)
        sys.exit(1)
