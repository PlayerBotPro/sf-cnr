"""Shared sampctl compilation for the server and isolated runtime checks."""
import json
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def compile_target(name, log_name=None):
    sampctl = shutil.which('sampctl')
    if not sampctl:
        raise RuntimeError('sampctl is not on PATH. Install sampctl 1.16.0; see RUNNING.md.')
    package = json.loads((ROOT / 'pawn.json').read_text(encoding='utf-8'))
    target = next(item for item in package['builds'] if item['name'] == name)
    output = ROOT / target['output']
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)
    result = subprocess.run([sampctl, 'build', '--verbose', name],
                            cwd=ROOT, capture_output=True)
    log = result.stdout + result.stderr
    runtime = ROOT / '.runtime'
    runtime.mkdir(exist_ok=True)
    log_path = runtime / f'build-{log_name or name}.log'
    log_path.write_bytes(log)
    diagnostics = [line for line in log.decode('cp936', errors='replace').splitlines()
                   if not line.startswith('INFO:')]
    if result.returncode or re.search(rb'\b(?:fatal )?error \d+[:)]', log) or not output.is_file():
        output.unlink(missing_ok=True)
        print('\n'.join(diagnostics[-80:]))
        raise RuntimeError(f'{name} compilation failed; see {log_path}. Previous deployed AMX retained.')
    if diagnostics:
        print('\n'.join(diagnostics))
    print(f'Compiled {name}; diagnostics: {log_path.relative_to(ROOT)}')
    return output
