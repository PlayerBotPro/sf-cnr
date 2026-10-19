"""Build and operate SA-MP using an externally managed XAMPP database."""
import argparse
import os
from pathlib import Path
import secrets
import socket
import struct
import subprocess
import sys
import time

from pawn_build import compile_target

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / '.runtime'
def config():
    return dict(line.split(None, 1) for line in (ROOT / 'server.cfg').read_text().splitlines()
                if line.strip() and len(line.split(None, 1)) == 2)


def packet(opcode):
    return b'SAMP' + socket.inet_aton('127.0.0.1') + struct.pack('<H', int(config()['port'])) + opcode


def query():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(1)
        sock.sendto(packet(b'i'), ('127.0.0.1', int(config()['port'])))
        data = sock.recv(4096)
    if not data.startswith(packet(b'i')):
        raise RuntimeError('Unexpected SA-MP query response')
    players, maximum = struct.unpack_from('<HH', data, 12)
    size = struct.unpack_from('<I', data, 16)[0]
    return {'hostname': data[20:20 + size].decode('latin1'), 'players': players, 'maxplayers': maximum}


def rcon(command):
    password = config()['rcon_password'].encode('ascii')
    command = command.encode('ascii')
    data = packet(b'x') + struct.pack('<H', len(password)) + password + struct.pack('<H', len(command)) + command
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.sendto(data, ('127.0.0.1', int(config()['port'])))


def check_database():
    try:
        with socket.create_connection(('127.0.0.1', 3306), timeout=3):
            pass
    except OSError as error:
        raise RuntimeError('Cannot reach MySQL at 127.0.0.1:3306. Start MySQL in XAMPP.') from error


def hidden_process(args):
    return subprocess.Popen(args, cwd=ROOT, creationflags=subprocess.CREATE_NO_WINDOW,
                            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def build():
    for name, folder, source in [('gamemode', 'gamemodes', 'sf-cnr'),
                                 ('npc', 'npcmodes', 'secureguard')]:
        output = ROOT / folder / f'{source}.amx'
        temporary = compile_target(name, source)
        temporary.replace(output)


def start():
    try:
        info = query()
    except (OSError, RuntimeError):
        info = None
    if info:
        print(f'SA-MP already responds on port {config()["port"]}: {info["hostname"]}')
        return
    for path in ['gamemodes/sf-cnr.amx', 'npcmodes/secureguard.amx', 'libmysql.dll', 'samp-server.exe']:
        if not (ROOT / path).is_file():
            raise RuntimeError(f'Missing {path}; run build.cmd or restore runtime dependencies')
    check_database()
    log = ROOT / 'server_log.txt'
    offset = log.stat().st_size if log.exists() else 0
    process = hidden_process([str(ROOT / 'samp-server.exe')])
    (RUNTIME / 'server.pid').write_text(str(process.pid))
    for _ in range(60):
        if process.poll() is not None:
            raise RuntimeError('SA-MP exited. Read server_log.txt')
        text = log.read_bytes()[offset:].decode('latin1') if log.exists() else ''
        if "[MYSQL]: Couldn't connect to MySQL database." in text:
            rcon('exit')
            raise RuntimeError('Database login failed. Configure sf_cnr on XAMPP; see DATABASE_SETUP.md.')
        if '[SF-CNR] SF-CnR has been successfully initialized.' in text:
            print(f'Running: {query()["hostname"]} at 127.0.0.1:{config()["port"]} (PID {process.pid})')
            return
        time.sleep(0.5)
    raise RuntimeError('SA-MP initialization timed out. Read server_log.txt')


def stop():
    try:
        query()
    except OSError:
        pass
    else:
        rcon('exit')
        for _ in range(30):
            time.sleep(0.5)
            try:
                query()
            except OSError:
                break
        else:
            raise RuntimeError('SA-MP did not stop')
    print('SA-MP stopped.')


def status():
    info = query()
    check_database()
    print(f'{info["hostname"]}: 127.0.0.1:{config()["port"]}, {info["players"]}/{info["maxplayers"]} players')
    print('XAMPP endpoint reachable: 127.0.0.1:3306 (database login is reported in server_log.txt)')


def test():
    folder = RUNTIME / 'tests'
    (folder / 'gamemodes').mkdir(parents=True, exist_ok=True)
    compile_target('runtime-check')
    (folder / 'server.cfg').write_text(f'rcon_password {secrets.token_hex(16)}\n'
                                      'bind 127.0.0.1\nport 7788\nmaxplayers 1\n'
                                      'announce 0\nquery 0\ngamemode0 runtime-check 1\n')
    log = folder / 'server_log.txt'
    offset = log.stat().st_size if log.exists() else 0
    subprocess.run([str(ROOT / 'samp-server.exe')], cwd=folder, timeout=30,
                   creationflags=subprocess.CREATE_NO_WINDOW, check=True)
    output = log.read_bytes()[offset:].decode('latin1')
    (RUNTIME / 'test-result.log').write_text(output)
    if '[RUNTIME CHECK] Completed: 0 failures' not in output:
        raise RuntimeError(output)
    print('Calculator and MT19937 tests passed in the stock SA-MP runtime.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['build', 'start', 'stop', 'status', 'test'])
    args = parser.parse_args()
    os.chdir(ROOT)
    RUNTIME.mkdir(exist_ok=True)
    try:
        globals()[args.action]()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Error: {error}', file=sys.stderr)
        sys.exit(1)
