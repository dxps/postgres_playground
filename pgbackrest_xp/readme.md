# PostgreSQL with pgBackRest experiment

TODO

The `openssh-server` image is taken from [here](https://hub.docker.com/r/linuxserver/openssh-server).

<br/>

## Setup

First, build a local docker image that the containers will use:

```shell
cd pg-sshd-ubuntu/
docker build -t pg-sshd-ubuntu:latest .
```

Start the three containers (named `pg1`, `pg2` and `pg3`) using their respective `./run_pgX.sh` scripts.

Add `pg1.sh` like scripts that uses `docker exec -it {container-name} /bin/bash`.

Enter to the containers using their respective `./pgX.sh` scripts to install some prerequisites:

1. Add `postgres` user to sudoers (very handy sometimes).\
   Example (from `pg1` host):
    ```shell
    root@pg1:/# grep sudo /etc/group
    sudo:x:27:ubuntu,postgres
    root@pg1:/#
    ```

<br/>

### Passwordless (SSH based) Authentication

#### Generate SSH keys

-   Enter into the container\
    (using `ssh postgres@localhost -p 2221` or `docker exec -it pg1 /bin/bash`)
-   Switch to `postgres` user\
    (using `su - postgres`)
-   Generate the keypair\
    (using `ssh-keygen -t rsa`)

#### Update `/etc/hosts` file

Just for convenience (it's easy to specify the (host)name instead of IP address), update `/etc/hosts` file on each host with the following lines:

```
172.17.0.2	pg1
172.17.0.3	pg2
172.17.0.4	pgbr
```

#### Copy the public keys to each others hosts

Copy the public key (from `~/.ssh/id_rsa.pub`) of `postgres` user from one host to the other (into `~/.ssh/authorized_keys` file of `postgres` user on that host).\
A shorter way is to use `ssh-copy-id` command such as `ssh-copy-id pg2` (which copies the public key of `postgres` user from `pg1` to `pg2`).

<br/>

### Init the secondary server

On `pg2` host, do:

1. Remove the existing data directory (`rm -rf /var/lib/postgresql/16/main/`)
2. Run `pg_basebackup -h pg1 -w -U postgres -F plain -X stream -R -S dxps_slot -C -D /var/lib/postgresql/16/main/` to copy the data from `pg1` to `pg2`.\
   where:
    - `-S` specifies the slot name
    - `-C` specifies to create the slot
    - `-X` specifies the wall method (shortcut for `--wal-method`).
        - Tells to include the required WAL files in the backtup.
        - `stream` tells to stream WAL data while the backup is being taken.
          It will open an second connection to the server.

Additionally, test the replication (from `pg1` to `pg2`) by creating a database in `pg1` instance and verify that this gets also created in `pg2` instance.

<br/>

### Run a full backup

Run a full backup from the repository host, that is `pgbr` host:\
`pgbackrest --stanza=demo --log-level-console=detail --type=full backup`

Check the backup status with `pgbackrest info` on any of the three hosts.

<br/>

### Restore the backup on a spare host

After starting up a fourth host (named `pgsp` in this case), prepare it to restore by:

1. Generating (using `ssh-keygen`) and copying its public key to `pgbr` using `ssh-copy-id pgbr`.
2. Populate its `/etc/pgbackrest.conf` file with:

    ```ini
    [global]
    repo1-host=pgbr
    repo1-host-user=postgres
    repo1-path=/var/lib/pgbackrest
    repo1-retention-full=2
    log-level-console=detail
    log-level-file=debug
    compress-level=6
    delta=y
    backup-standby=y
    start-fast=y

    [demo]
    pg1-user=postgres
    pg1-path=/var/lib/postgresql/16/main
    ```

Run the restore (that is done using the repository host, that is `pgbr` host):\
`pgbackrest --stanza=demo --log-level-console=detail restore`
