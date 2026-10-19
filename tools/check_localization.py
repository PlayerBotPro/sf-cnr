"""Audit the Chinese Pawn localization against its English Git baseline.

This checks source and compiled bytes, not client font support or gameplay.
"""
import argparse
import re
import struct
import subprocess
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = 'd49b450fd9ceca06f45268cd2741afc503a6f9f8'
LEX = re.compile(rb'//[^\r\n]*|/\*[\s\S]*?\*/|\'(?:\\.|[^\'\\\r\n])*\'|"(?:\\(?:\r?\n|.)|[^"\\])*"')
FORMAT = re.compile(rb'%(?:[-+0#]*\d*(?:\.\d+)?[a-zA-Z%])')
COLORS = re.compile(rb'\{(?:[A-Fa-f0-9]{6,8}|%[^}]+)\}')
KEYS = re.compile(rb'~k~~[A-Z_]+~|~[A-Za-z<>\]\[]~')
COMMANDS = re.compile(rb'(?<![A-Za-z0-9_\x80-\xff])/(?:\([a-zA-Z]+\))?[a-zA-Z][a-zA-Z0-9_]*(?: (?:accept|join|leave|stopspawn|sell/bring|sell|cook|fight|respawn|locate|paintjob|config)\b)?')
PLURAL = b'((seconds / times[i]) == 1) ? ("") : ("s")'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def unescape(value):
    """Resolve Pawn decimal byte escapes without converting bytes to Unicode."""
    value = value[1:-1]
    value = re.sub(rb'\\\r?\n[ \t]*', b'', value)
    value = re.sub(rb'\\(\d+);', lambda m: bytes([int(m[1])]), value)
    return re.sub(rb'\\([nrt"\\])', lambda m: {
        b'n': b'\n', b'r': b'\r', b't': b'\t', b'"': b'"', b'\\': b'\\'
    }[m[1]], value)


def without_display_tables(source):
    for name in (b'g_jobDisplayNames', b'g_aVehicleDisplayNames', b'HAND_RANKS_ZH',
                 b'gSACityDisplayNames', b'gSAZoneDisplayNames',
                 b'g_houseInteriorDisplayNames', b'g_roadblockDisplayNames'):
        source = re.sub(rb'(?:static|stock|new) const ' + name
                        + rb'\[[^;]*?\r?\n\};\r?\n', b'', source)
    return source


def normalize(file, source):
    source = without_display_tables(source)
    source = re.sub(rb'GetLocationDisplayName\((\w+)\)', rb'\1', source)
    if file.endswith('/map.pwn'):
        source = re.sub(rb'\r?\nstock GetLocationDisplayName\(const name\[\]\)[\s\S]*$', b'', source)
    if file.endswith('/house.pwn'):
        source = re.sub(rb'g_houseInteriorDisplayNames\s*\[([^\]]+)\]',
                        rb'g_houseInteriors[\1][E_NAME]', source)
    if file.endswith('/roadblocks.pwn'):
        source = re.sub(rb'g_roadblockDisplayNames\s*\[([^\]]+)\]',
                        rb'g_roadblockObjectData[\1][E_NAME]', source)
    if file.endswith('/jobs.pwn'):
        source = source.replace(b'g_jobDisplayNames', b'g_jobsData')
    if file.endswith('/vehicle_data.pwn'):
        source = source.replace(b'g_aVehicleDisplayNames', b'g_aVehicleNames')
    if file.endswith('/poker.pwn'):
        source = source.replace(b'HAND_RANKS_ZH', b'HAND_RANKS')
    if file.endswith('/helpers.pwn'):
        source = source.replace(PLURAL, b'""')
    return source


def structure(source):
    def token(match):
        if match[0].startswith((b'//', b'/*')):
            return b''
        return b'""' if match[0].startswith(b'"') else match[0]
    return re.sub(rb'\s+', b'', LEX.sub(token, source))


def strings(source):
    return [m for m in LEX.finditer(source) if m[0].startswith(b'"')]


def amx_cells(program):
    """Expand 32-bit compact cells, following pawn-lang's amx.c expand().

    Reference: https://github.com/pawn-lang/compiler/blob/master/source/amx/amx.c
    """
    size, magic, _, _, flags, _, code, _, heap = struct.unpack_from('<IHBBHHIII', program)
    if magic != 0xF1E0:
        raise ValueError('Expected a 32-bit Pawn AMX')
    if not flags & 4:
        return program[code:heap]
    expanded = bytearray(heap - code)
    source, target = size - 1, len(expanded)
    while source >= code:
        value, shift = 0, 0
        while True:
            byte = program[source]
            source -= 1
            value |= (byte & 0x7f) << shift
            shift += 7
            if source < code or not program[source] & 0x80:
                break
        if byte & 0x40:
            value |= -1 << shift
        target -= 4
        if target < 0:
            raise ValueError('Invalid compact AMX size')
        struct.pack_into('<I', expanded, target, value & 0xffffffff)
    if target:
        raise ValueError('Incomplete compact AMX')
    return expanded


def runtime_check():
    folder = ROOT / '.runtime/localization-tests'
    (folder / 'gamemodes').mkdir(parents=True, exist_ok=True)
    (folder / 'scriptfiles').mkdir(exist_ok=True)
    from pawn_build import compile_target
    compile_target('localization-check')
    (folder / 'server.cfg').write_text(
        f'rcon_password {secrets.token_hex(16)}\nbind 127.0.0.1\nport 7789\n'
        'maxplayers 1\nannounce 0\nquery 0\ngamemode0 localization-check 1\n')
    log = folder / 'server_log.txt'
    offset = log.stat().st_size if log.exists() else 0
    # The test gamemode exits itself; this never stops the normal server.
    subprocess.run([str(ROOT / 'samp-server.exe')], cwd=folder, timeout=15, check=True,
                   creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    output = log.read_bytes()[offset:].decode('cp936', errors='replace')
    if '[LOCALIZATION CHECK] Completed: 0 failures' not in output:
        raise RuntimeError(output)
    print('Isolated SA-MP localization checks passed (port 7789).')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default=BASELINE)
    parser.add_argument('--amx', type=Path, help='Optionally verify emitted CP936 text in the built AMX')
    parser.add_argument('--runtime', action='store_true', help='Run isolated SA-MP lookup/display checks on port 7789')
    args = parser.parse_args()
    files = git('diff', '--name-only', args.base, '--', 'gamemodes').decode().splitlines()
    errors = []
    changed = 0
    checked = 0
    for file in files:
        if not file.endswith('.pwn'):
            continue
        original = git('show', f'{args.base}:{file}')
        current = (ROOT / file).read_bytes()
        checked += 1
        try:
            assert current.decode('cp936').encode('cp936') == current
        except (UnicodeError, AssertionError):
            errors.append(f'{file}: CP936 round trip failed')
        if current.startswith(b'\xef\xbb\xbf') or current.count(b'\n') != current.count(b'\r\n'):
            errors.append(f'{file}: unexpected BOM or line endings')
        a, b = normalize(file, original), normalize(file, current)
        if structure(a) != structure(b):
            errors.append(f'{file}: unexpected non-string code change')
        before, after = strings(a), strings(b)
        if len(before) != len(after):
            errors.append(f'{file}: string count changed ({len(before)} -> {len(after)})')
            continue
        for old, new in zip(before, after):
            left, right = unescape(old[0]), unescape(new[0])
            if left == right:
                continue
            changed += 1
            line = b.count(b'\n', 0, new.start()) + 1
            for label, pattern in [('format arguments', FORMAT), ('colors', COLORS),
                                   ('GameText/key tokens', KEYS), ('commands', COMMANDS),
                                   ('line/tab escapes', re.compile(rb'[\n\r\t]'))]:
                if pattern.findall(left) != pattern.findall(right):
                    errors.append(f'{file}:{line}: changed {label}: {left!r} -> {right!r}')
            if b'`' in left or re.search(rb'\b(?:SELECT|INSERT INTO|UPDATE|DELETE FROM)\b', left):
                errors.append(f'{file}:{line}: SQL string changed')
    if args.amx:
        amx = amx_cells(args.amx.read_bytes())
        for sample in ('账号 - 注册', '当前经验', '选择职业', '圣菲耶罗警匪'):
            needle = b''.join(struct.pack('<I', byte) for byte in sample.encode('cp936'))
            if needle not in amx:
                errors.append(f'AMX missing expected CP936 sample: {sample}')
    for error in errors:
        print(error)
    print(f'Audited {checked} Pawn files and {changed} changed literals; {len(errors)} issue(s).')
    if args.runtime and not errors:
        runtime_check()
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
