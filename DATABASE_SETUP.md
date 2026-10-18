# Database setup

SF-CNR can use the MySQL/MariaDB server already running in XAMPP on **port 3306**.
Create a database named `sf_cnr` and a dedicated user inside that server.
You do not need another MariaDB process.

The server scripts use the existing XAMPP database service. Start MySQL through
XAMPP before starting SA-MP. The scripts do not start or shut down MySQL.

## 1. Open the XAMPP database

Start MySQL from the XAMPP Control Panel. Open PowerShell and connect explicitly
to port 3306 using an administrator account:

```powershell
& 'D:\Software\xampp\mysql\bin\mysql.exe' --no-defaults --host=127.0.0.1 --port=3306 --user=root --password
```

Enter the existing root password at the prompt. If your local root account has
no password, press Enter. Use your actual administrator account if it is not
`root`.

Check which instance you connected to:

```sql
SELECT VERSION(), @@port, @@datadir;
SHOW DATABASES LIKE 'sf_cnr';
```

The port should be `3306`. If `sf_cnr` already exists, inspect it before
continuing. The fresh-install steps below assume that name is unused.

## 2. Create the database

Run this in the MySQL client, or in phpMyAdmin's SQL tab while connected to the
same instance:

```sql
CREATE DATABASE `sf_cnr`
    CHARACTER SET latin1
    COLLATE latin1_swedish_ci;
```

The repository's original table definitions use `latin1`. This preserves that
schema; changing text encoding is a separate migration.

## 3. Create the game-server user

Replace `REPLACE_WITH_A_LONG_RANDOM_PASSWORD` with your own password. Keep the
same password in both statements and in the Pawn configuration later.

```sql
CREATE USER 'sf_cnr'@'127.0.0.1'
    IDENTIFIED BY 'REPLACE_WITH_A_LONG_RANDOM_PASSWORD';

GRANT ALL PRIVILEGES ON `sf_cnr`.* TO 'sf_cnr'@'127.0.0.1';

CREATE USER 'sf_cnr'@'localhost'
    IDENTIFIED BY 'REPLACE_WITH_A_LONG_RANDOM_PASSWORD';

GRANT ALL PRIVILEGES ON `sf_cnr`.* TO 'sf_cnr'@'localhost';
```

The two local host entries cover local connections with and without hostname
resolution. These grants apply only to `sf_cnr`, not your other databases.
The gamemode should use this account instead of root.

`CREATE USER` reports an error if that account already exists. To intentionally
change an existing account's password, use `ALTER USER` instead:

```sql
ALTER USER 'sf_cnr'@'127.0.0.1' IDENTIFIED BY 'YOUR_NEW_PASSWORD';
ALTER USER 'sf_cnr'@'localhost' IDENTIFIED BY 'YOUR_NEW_PASSWORD';
```

`FLUSH PRIVILEGES` is not needed after `CREATE USER`, `ALTER USER`, or `GRANT`.

## 4. Import the schema and initial data

For a **fresh database**, import these files once, in this order. The following
commands run inside the MySQL command-line client, not PowerShell:

```sql
USE `sf_cnr`;

SOURCE D:/Code/sf-cnr/gamemodes/irresistible/config/migrations/cnr/20181212_cnr_base.sql;
SOURCE D:/Code/sf-cnr/gamemodes/irresistible/config/migrations/cnr/20190101_cnr_remove_xp_autosave.sql;
SOURCE D:/Code/sf-cnr/gamemodes/irresistible/config/migrations/cnr/20190401_cnr_remove_passive_mode.sql;
SOURCE D:/Code/sf-cnr/gamemodes/irresistible/config/migrations/cnr/20190405_cnr_chat_ban_creation.sql;
SOURCE D:/Code/sf-cnr/gamemodes/irresistible/config/migrations/cnr/20190530_cnr_realestate_ask.sql;
```

Check each import for errors before running the next. In phpMyAdmin, select
`sf_cnr`, open **Import**, and import the same five files individually in order.
`SOURCE` is a command-line client command and does not work in phpMyAdmin's SQL tab.

Verify the result:

```sql
SHOW TABLES;
SELECT `MIGRATION` FROM `DB_MIGRATIONS` ORDER BY `MIGRATION`;
SELECT COUNT(*) AS registered_accounts FROM `USERS`;
```

There should be five migration records. Do not rerun all five files against a
database that already contains the current schema. Some migrations drop columns
or clear tables.

## 5. Configure the gamemode

Edit `gamemodes/irresistible/config/database.pwn`. If the file is missing, copy
`database.pwn.sample` to that name first.

Set these definitions in the active configuration branch:

```pawn
#define MYSQL_HOST       "127.0.0.1"
#define MYSQL_USER       "sf_cnr"
#define MYSQL_PASS       "REPLACE_WITH_A_LONG_RANDOM_PASSWORD"
#define MYSQL_DATABASE   "sf_cnr"
```

`DEBUG_MODE` is currently defined in `gamemodes/sf-cnr.pwn`, so the `#else`
branch is active. Configure both branches if you want the same database when
debug mode is disabled.

The `mysql_connect` call uses port `3306`:

```pawn
dbHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASS, 3306);
```

Keep the surrounding `mysql_errno` error check. The line above shows only the
connection expression. The R39-6 argument order is **host, user, database,
password, port**.

The credentials are compiled into the AMX. Rebuild after changing them:

```powershell
Set-Location D:\Code\sf-cnr
.\build.cmd
```

`database.pwn` is ignored by Git. Do not copy its real password into tracked docs.

## 6. Test the connection and start SA-MP

First test the dedicated user directly:

```powershell
& 'D:\Software\xampp\mysql\bin\mysql.exe' --no-defaults --host=127.0.0.1 --port=3306 --user=sf_cnr --password --database=sf_cnr
```

Inside the client:

```sql
SELECT DATABASE(), CURRENT_USER(), @@port;
SHOW GRANTS;
SELECT COUNT(*) FROM `DB_MIGRATIONS`;
```

Exit the client with `exit`. Keep XAMPP MySQL running. Stop any existing SA-MP
process before starting the rebuilt server from the repository:

```powershell
Set-Location D:\Code\sf-cnr
.\start-server.cmd
```

Look in `server_log.txt` for:

```text
[MYSQL]: Connection to database is successful.
[SF-CNR] SF-CnR has been successfully initialized.
```

`stop-server.cmd` stops only SA-MP. `server-status.cmd` queries SA-MP and checks
that the XAMPP database endpoint is reachable; authentication success is recorded
in `server_log.txt`. Manage MySQL itself through XAMPP.

## Troubleshooting

| Message or symptom | Check |
| --- | --- |
| Cannot connect | XAMPP MySQL is running; host is `127.0.0.1`; port is `3306` |
| Access denied | Username, password, host-specific account, and database grants |
| Unknown database | `sf_cnr` was created on the instance you are connecting to |
| Missing table or column | Correct database selected; schema files imported in order |
| Field has no default value on inserts | The legacy gamemode expects permissive SQL mode; check the note below |

The legacy gamemode may require permissive SQL mode. To inspect XAMPP's mode:

```sql
SELECT @@GLOBAL.sql_mode, @@SESSION.sql_mode;
```

If strict-mode errors occur, either fix the affected inserts/defaults or configure
compatibility deliberately. XAMPP's MySQL configuration can use `sql_mode=""`
under `[mysqld]` to enable permissive mode, followed by a MySQL restart.
That setting affects **every application using that XAMPP instance**, so check
their requirements before changing it. Setting SQL mode in your interactive
client alone does not change the gamemode's connections.
