# Package and update the Windows server

After editing, run from PowerShell:

```powershell
.\distribute.cmd
```

Requires Python 3.9+, sampctl and Git on PATH, restored build dependencies
(`sampctl ensure`), the private `database.pwn` configured for the destination
database, and the installed Windows runtime described in RUNNING.md.
The command works from any current directory. It rebuilds both the gamemode and
NPC, checks runtime files, creates the ZIP, then verifies its CRCs. A failed
build or missing runtime asset prevents a new ZIP from being published.

Output: `dist/sf-cnr-windows-<timestamp>.zip`. To choose a filename:

```powershell
.\distribute.cmd --output dist\my-update.zip
```

An existing output file is never replaced. The ZIP contains paths relative to
the server root, ready for extraction, without an extra enclosing directory.

## Contents

- Windows SA-MP server, NPC and announcement executables, plus `libmysql.dll`.
- Fresh `sf-cnr.amx` and `secureguard.amx`, plus any other gamemodes and
  filterscripts named in `server.cfg` (these additional AMX files must already
  be compiled).
- `server.cfg` and all installed plugin DLLs, including companion DLLs.
- NPC recordings, both MapAndreas heightmaps, changelogs and COD map assets.
- CNR migration SQL, launch/stop/status shortcuts, their Python helper,
  operating/database instructions and the project license.

Sources, compiler/includes, dependency caches, logs, local process IDs, ban
lists and database dumps are excluded. The MySQL/MariaDB service is external
and must already be installed and configured on the destination. The ZIP is
for the Windows x86 runtime in this checkout; Linux hosting requires a separate
runtime and plugin setup.

Keep the ZIP private: `server.cfg` contains the RCON password, and the compiled
gamemode embeds database credentials. Changing database credentials requires
editing the private source configuration and packaging again; no standalone
database configuration file is needed on the destination.

## Update an existing server

1. Back up the destination server folder and its database. Stop SA-MP using
   `stop-server.cmd` or your hosting control panel before replacing files.
2. Extract the ZIP into a separate staging folder. Keep the destination's
   `server.cfg` unless you intend to replace its port, RCON password and other
   settings with the packaged configuration. Confirm the built-in database
   credentials point to the intended destination database.
3. Copy the staged files into the destination server root, replacing packaged
   files. Preserve destination logs, ban lists, saves and other local data.
   The scriptfiles assets in the ZIP replace files with matching paths, so
   merge any destination customizations before copying. This is an overlay;
   obsolete files from previous releases are not automatically deleted.
4. Review database changes separately. Do not reimport the base schema on an
   existing database. Apply only required, unapplied migrations following
   DATABASE_SETUP.md; packaging does not run SQL or transfer player data.
5. Start MySQL/MariaDB, then run `start-server.cmd` (requires Python on the
   destination) or launch `samp-server.exe` with the server root as its working
   directory. The shortcuts check the existing local database endpoint at
   `127.0.0.1:3306`. For a remote database, use the executable and your host's
   process manager instead. Check `server_log.txt` for plugin loading and
   successful gamemode/database initialization, then test login and gameplay.

For a fresh server, extract into an empty directory and complete the database
setup and runtime prerequisites in DATABASE_SETUP.md and RUNNING.md first.
Packaging and CRC checks do not establish live gameplay compatibility.
