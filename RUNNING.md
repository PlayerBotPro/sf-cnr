# Running this checkout on Windows

For Chinese player text, encoding, exclusions, and validation, see
[LOCALIZATION.zh-CN.md](LOCALIZATION.zh-CN.md).

For database/user creation, schema imports, and using an existing XAMPP instance
on port 3306, see [DATABASE_SETUP.md](DATABASE_SETUP.md).

Run `start-server.cmd`, then connect with SA-MP 0.3.7 to **127.0.0.1:7777**.
Start MySQL in XAMPP first and complete [DATABASE_SETUP.md](DATABASE_SETUP.md).
The command starts SF-CNR in the background and uses XAMPP on port 3306.
Python 3 must be available as `python`.
Building also requires sampctl on `PATH`; see [sampctl builds](#sampctl-builds).

| Command | Purpose |
| --- | --- |
| `start-server.cmd` | Start the game server using XAMPP; report initialization |
| `stop-server.cmd` | Stop SA-MP through local RCON; leave XAMPP running |
| `server-status.cmd` | Query SA-MP and check that the XAMPP endpoint is reachable |
| `sampctl build gamemode` | Compile `gamemodes/sf-cnr.amx` |
| `sampctl build npc` | Compile `npcmodes/secureguard.amx` |
| `python tools/server.py test` | Test calculator expressions and MT19937 in a separate SA-MP instance on port 7788 |

After editing Pawn source, stop the server, run the relevant sampctl build
command(s), then start it again.
The scripts work from any current directory and do not require a Windows service.

## sampctl builds

Install [sampctl 1.16.0](https://github.com/Southclaws/sampctl/releases/tag/1.16.0)
and Git on `PATH`, plus Python 3 for server management and runtime checks.
The compiler and includes are managed by sampctl. No `pawno/` directory is needed. The previous local installation was moved
to the ignored `.runtime/legacy-pawno/` as a backup.

From a fresh clone, run:

```powershell
sampctl --version
sampctl ensure
Copy-Item gamemodes/irresistible/config/database.pwn.sample gamemodes/irresistible/config/database.pwn
# Edit database.pwn with your local database settings before running the server.
sampctl build gamemode
sampctl build npc
```

Create the private database configuration only when it does not exist. Complete
[DATABASE_SETUP.md](DATABASE_SETUP.md) for the schema, database user, and XAMPP.
The sample can be used to compile without a running database; compilation does
not validate its credentials. Never commit the private configuration or AMX files
(which embed those credentials).

`pawn.json` declares 13 upstream include packages. `pawn.lock` records their
resolved commits and must be committed. MySQL R39-6, Streamer 2.9.3, sscanf 2.8.2,
MapAndreas 1.2.1, FCNPC 1.8.2, and progress2 2.1.2 use release tags. YSI uses release `v4.0.2`; the remaining libraries use explicit commit pins.
SA-MP standard includes use the stock `0.3.7-R2-2-1` tag, and Pawn standard
includes use the original snapshot matching the supplied server archive. Four archived headers (`GVar`, `regex`, `modelsizes`,
`SAMPCAC`) are committed under `vendor/includes/` with provenance and hashes in
[vendor/README.md](vendor/README.md). No standard library is copied from Pawno.

All four targets select the downloaded **pawn-lang/compiler 3.10.8**. Sampctl
fetches the compiler on the first build. Gamemode/NPC builds retain
`AMX_OLD_CALL=1` to select the assembly library adapter for YSI 4.0.2.
The default VS Code build task (Ctrl+Shift+B) runs both sampctl builds in
sequence. Building requires sampctl and Git; Python is used only for server
management, runtime checks, and dependency integrity maintenance.

| Command | Output |
| --- | --- |
| `sampctl build gamemode` (or `sampctl build`) | `gamemodes/sf-cnr.amx` |
| `sampctl build npc` | `npcmodes/secureguard.amx` |
| `sampctl build runtime-check` | `.runtime/tests/gamemodes/runtime-check.amx` |
| `sampctl build localization-check` | `.runtime/localization-tests/gamemodes/localization-check.amx` |

Sampctl writes the final AMX files directly and reports compiler diagnostics in
the terminal. The former `build.cmd`, Python build command, and shared build
helper have been removed. Direct compilation no longer preserves the previous
AMX on failure; check the exit status and rebuild successfully before starting
the server.

Use `python tools/server.py test` and
`python tools/check_localization.py --runtime` for the runtime checks; their
compiler steps invoke the corresponding sampctl targets directly. Server
management shortcuts (`start-server.cmd`, `stop-server.cmd`, and
`server-status.cmd`) remain available.

Sampctl may download release assets declared by dependency packages and a stock
SA-MP runtime during `ensure`. These are installed under
`.runtime/sampctl-server/` to keep dependency provisioning separate from the
configured server in the repository root. This staging runtime is not configured
for SF-CNR. The installed root plugin DLLs, `libmysql.dll`, MapAndreas heightmaps,
recordings, database, and `server.cfg` remain runtime prerequisites listed below.
Use `start-server.cmd` / `stop-server.cmd` for the configured root server.

To refresh declared dependencies, run `sampctl ensure` and review `pawn.lock`.
For intentional upgrades, edit the pins in `pawn.json`, ensure again, and review
both files plus the compiler diagnostics. Keep plugin DLLs and include versions
matched. `dependencies/` is generated; edits there are overwritten. See the
[sampctl migration guide](https://github.com/sampctl/tutorial-migration) and
[dependency reference](https://github.com/Southclaws/sampctl/blob/1.16.0/docs/dependencies.md).

If GitHub reports an API rate limit, set `SAMPCTL_GITHUB_TOKEN` in your local
environment and retry. Keep tokens outside tracked files.

Three legacy upstream packages mark source files executable in Git. Sampctl
1.16's commit integrity check reports these as modified on Windows even when
all bytes match. Their checked-in lock entries therefore use sampctl's supported
SHA-256 source integrity format. After intentionally upgrading either standard
library or YSI, run `python tools/refresh_dependency_integrity.py` after ensure
and commit the refreshed lock. The script first verifies every relevant file
against the locked Git blob; it refuses changed or extra source files. These
hash records use sampctl's Windows path conventions. Linux builds are unverified.

If sampctl reports Windows `Access is denied` while promoting a generated clone,
close tools holding that dependency directory open and retry `sampctl ensure`.
No installed dependency needs to be edited manually.

## Local configuration and data

- `server.cfg`: port 7777, announcements disabled, random RCON password, 336
  total slots and 210 NPC slots. The gamemode exposes 126 human slots in queries.
- `gamemodes/irresistible/config/database.pwn`: local database credentials,
  database `sf_cnr`, TCP port 3306. Keep this file private; rebuild after edits.
- `server_log.txt`, `mysql_log.txt`: runtime logs. Compiler diagnostics are printed by `sampctl build` in the terminal.

Create the database and user and import the five CNR SQL files as described in
[DATABASE_SETUP.md](DATABASE_SETUP.md). The scripts do not initialize a database,
reimport schemas, or manage the XAMPP service. Back up `sf_cnr` through XAMPP's
MySQL tools or phpMyAdmin and keep the ignored Pawn credentials separately.
Runtime binaries, credentials, and logs are ignored by Git.

## Installed runtime

The existing root server executables came from the supplied archive:
`D:\Game\gtasa_setup\game\SAMP Server\samp037_svr_R2-2-1_win32.zip`.
This is the stock **SA-MP 0.3.7 R2 Windows x86 server**.

| Dependency | Installed version/source |
| --- | --- |
| Pawn compiler | pawn-lang/compiler 3.10.8 Windows |
| YSI | pawn-lang/YSI-Includes v4.0.2; amx_assembly includes; build defines `AMX_OLD_CALL=1` |
| MySQL | pBlueG/SA-MP-MySQL R39-6, including its matching root `libmysql.dll` |
| Streamer | samp-incognito/samp-streamer-plugin 2.9.3 |
| GVar | samp-incognito/samp-gvar-plugin 1.3 |
| sscanf | Y-Less/sscanf 2.8.2 |
| Whirlpool | Southclaws/samp-whirlpool 1.0.0 |
| FCNPC | ziggi/FCNPC 1.8.2, compatible with SA-MP 0.3.7 R2 |
| MapAndreas | philip1337/samp-plugin-mapandreas 1.2.1, with SAfull/SAmin heightmaps |
| RouteConnectorPlugin | grasmanek94/SA-MP-GPS, matching include and Windows binaries |
| SAMPCAC | 0.10.0 server/include from ins1x/sampcac-docs archive |
| TPoker | DLL already supplied by this repository |
| CrashDetect | 4.20, copied from the existing local server dependencies |
| regex | Fro1sha 0.2.1; DLL from GRGServer/SAMP and matching local include |
| Other includes | zcmd, Y-Less modelsizes gist 4543512, oscar-broman/md-sort, Southclaws/progress2 v2.1.2 |

Legacy runtime archives are retained under `.runtime/`, and the active server
plugins are in `plugins/`. Sampctl downloads build dependencies into
`dependencies/` and the selected compiler into its user cache. The table above
describes the separately provisioned root runtime; the build no longer uses Pawno.
Use the runtime versions above when reconstructing a fresh clone. The historical
[setup guide](https://raw.githubusercontent.com/wiki/zekodef/sf-cnr/Server-Setup-Guide.md)
provides the original dependency list; several of its download links have disappeared.

`MerRandom` and `MathParser` were replaced with source files in
`gamemodes/irresistible/compat/`. Casino `MRandom` calls use MT19937 with bounded
sampling. `/calc` supports decimal numbers, parentheses, unary signs, and
`+ - * / % ^`; malformed expressions and division by zero return errors.
No MerRandom DLL is required. The remaining twelve plugins load normally.
The optional SAMPCAC sample filterscript is not configured.

The existing `DEBUG_MODE` remains enabled: upstream skips inactive-account
maintenance and the additional player-object map in this mode. Account login
and persistence still use MySQL. Legacy external help/audio/site URLs remain
in the gamemode and their availability has not been verified.

## Validation

Migration verification (2026-10-20): dependency restoration and both builds passed in
a clean source snapshot with the sample database config and no Pawno or existing
dependency directories. This used a warmed sampctl download cache; a fully cold
network bootstrap was limited by GitHub's unauthenticated API quota. All four
sampctl build targets passed. The calculator/MT19937 runtime tests and the
localization audit/runtime checks passed (126 Pawn files, 8,103 changed literals,
zero issues). The gamemode introduces no new native imports compared with the
previous build. The NPC retains its existing warning 218.

The existing root server was not restarted for migration testing; its earlier plugin/startup checks
predate this compiler/include migration.

Verified locally: gamemode compilation, NPC compilation (one existing warning
218) and the isolated compatibility tests. Earlier runtime checks covered all
twelve plugins, gamemode initialization, NPC startup and UDP queries. Database
startup must be checked again after configuring `sf_cnr` in XAMPP on port 3306. The isolated runtime test checks expression
precedence/errors, known MT19937 outputs, and random bounds.

CrashDetect can report a long callback during YSI's startup code scan; the
gamemode continues initializing afterward.

GTA client gameplay, player registration/login, and saved-account reloads still
need an in-game test. Successful startup alone does not verify those paths.
