# Gossamer Server: Docker Edition

This is a containerized version of [Paragonie](https://paragonie.com/)'s
[Gossamer Server](https://github.com/paragonie/gossamer-server).

## Requirements

To run the dockerized Gossamer Server, you must have [Docker](https://www.docker.com) and
[Docker Compose](https://docs.docker.com/compose/) installed.

## Setup

The first step is to setup **credentials** for database access. You can do that by setting values in:
* [secrets/postgres-user.txt](secrets/postgres-user.txt) - Database username
* [secrets/postgres-passwd.txt](secrets/postgres-passwd.txt) - Database password
* [secrets/postgres-db.txt](secrets/postgres-db.txt) - Database name

> Note: remove the `-dist` suffix from each secret file before moving to the next step!

The next step is to create the **containers**, you can do that by running `docker compose create`.

Now you can start your **instance**, by running `docker compose start`.

At this point, your instance is accessible at [localhost](http://localhost), but is not yet functional (ie. you can
access it, but it's not really working).

Run `./cli.sh` to get a disposable container, that gives you access to all gossamer-server's `bin/*` scripts.

To setup the **database**, execute `php configure` (in the disposable container's shell), like the example below:

```bash
$ ./cli.sh
/var/www/html/bin $ php configure
Please enter a command from the list below then press ENTER.

 +-----------+------------------------------------------------+
 | Command   | Description                                    |
 +-----------+------------------------------------------------+
 | chronicle | Add/remove Chronicle instances                 |
 | commands  | Show this table of available commands          |
 | database  | Configure the database connection              |
 | preview   | View the current configuration state           |
 | save      | Save the configuration to local/settings.php   |
 | super     | Set the "Super Provider"                       |
 | exit      | Exit this configuration program                |
 +-----------+------------------------------------------------+

Please enter your command: database
Please select a driver from the following list. [mysql, pgsql, sqlite]
Driver: pgsql
PostgreSQL hostname (localhost): postgres
PostgreSQL port (5432): <enter>
PostgreSQL username: <the contents of secrets/postgres-user.txt>
PostgreSQL password: <the contents of secrets/postgres-passwd.txt>
PostgreSQL database name: <the contents of secrets/postgres-db.txt>
Database configured!
Please enter your command: save
Saved.
Please enter your command: exit
```

Now execute the database **migration**, running `php make`.

For last, but not least, **sync** your instance data by running `php sync`.

## Utilities

### Command Line Interface

You can access all `bin/*` scripts by running `./cli.sh`, it will start a disposable container and give you access to a
shell that is in the same network as your Gossamer Server and the PostgreSQL Server. It also shares the `local`
directory with your Gossamer Server.

### Terminal-based front-end to PostgreSQL (psql)

You can use `psql` by running the following command: `docker compose exec postgres sh`, once you get access to the shell,
you can now run `pgsql -U $(cat /run/secrets/postgres-user) $(cat /run/secrets/postgres-db)`, this gets you access to
the database without having to type any credential.
