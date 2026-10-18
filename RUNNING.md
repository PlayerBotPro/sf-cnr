# Running this checkout on Windows

For database/user creation, schema imports, and using an existing XAMPP instance
on port 3306, see [DATABASE_SETUP.md](DATABASE_SETUP.md).

Run `start-server.cmd`, then connect with SA-MP 0.3.7 to **127.0.0.1:7777**.
Start MySQL in XAMPP first and complete [DATABASE_SETUP.md](DATABASE_SETUP.md).
The command starts SF-CNR in the background and uses XAMPP on port 3306.
Python 3 must be available as `python`.

| Command | Purpose |
| --- | --- |
| `start-server.cmd` | Start the game server using XAMPP; report initialization |
| `stop-server.cmd` | Stop SA-MP through local RCON; leave XAMPP running |
| `server-status.cmd` | Query SA-MP and check that the XAMPP endpoint is reachable |
| `build.cmd` | Compile the gamemode and security-truck NPC; retain previous AMX files on failure |
| `python tools/server.py test` | Test calculator expressions and MT19937 in a separate SA-MP instance on port 7788 |

After editing Pawn source, stop the server, run `build.cmd`, then start it again.
The scripts work from any current directory and do not require a Windows service.

## Local configuration and data

- `server.cfg`: port 7777, announcements disabled, random RCON password, 336
  total slots and 210 NPC slots. The gamemode exposes 126 human slots in queries.
- `gamemodes/irresistible/config/database.pwn`: local database credentials,
  database `sf_cnr`, TCP port 3306. Keep this file private; rebuild after edits.
- `server_log.txt`, `mysql_log.txt`: runtime logs. Compiler output is saved in
  `.runtime/build-sf-cnr.log` and `.runtime/build-secureguard.log`.

Create the database and user and import the five CNR SQL files as described in
[DATABASE_SETUP.md](DATABASE_SETUP.md). The scripts do not initialize a database,
reimport schemas, or manage the XAMPP service. Back up `sf_cnr` through XAMPP's
MySQL tools or phpMyAdmin and keep the ignored Pawn credentials separately.
Runtime binaries, credentials, and logs are ignored by Git.

## Installed runtime

The executables and standard Pawn includes came from the supplied archive:
`D:\Game\gtasa_setup\game\SAMP Server\samp037_svr_R2-2-1_win32.zip`.
This is the stock **SA-MP 0.3.7 R2 Windows x86 server**.

| Dependency | Installed version/source |
| --- | --- |
| Pawn compiler | pawn-lang/compiler 3.10.8 Windows |
| YSI | pawn-lang/YSI-Includes 4.x; amx_assembly includes; build defines `__YSI_CALL_UPGRADED=1` |
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

The downloaded archives and extracted dependency sources are retained under
`.runtime/`; compiler/includes are installed in `pawno/`, and plugins in `plugins/`.
Use the versions above when reconstructing a fresh clone. The historical
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

Verified locally: gamemode compilation, NPC compilation (one existing warning
218) and the isolated compatibility tests. Earlier runtime checks covered all
twelve plugins, gamemode initialization, NPC startup and UDP queries. Database
startup must be checked again after configuring `sf_cnr` in XAMPP on port 3306. The isolated runtime test checks expression
precedence/errors, known MT19937 outputs, and random bounds.

CrashDetect can report a long callback during YSI's startup code scan; the
gamemode continues initializing afterward.

GTA client gameplay, player registration/login, and saved-account reloads still
need an in-game test. Successful startup alone does not verify those paths.
