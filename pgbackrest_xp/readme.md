# PostgreSQL with pgBackRest experiment

This is an experiment to set up a PostgreSQL HA cluster with pgBackRest.

<br/>

## General Setup

### Build the Docker image

First of all, build a local Docker image of `pg-sshd-ubuntu` that is included in this repo.
This image is used by all the PostgreSQL related containers. Build the image as follows:

```shell
cd pg-sshd-ubuntu/
docker build -t pg-sshd-ubuntu:latest .
```

Start the three containers (named `pg1`, `pg2` and `pg3`) using their respective `./run_pgX.sh` scripts.

Add `pg1.sh` like scripts that uses `docker exec -it {container-name} /bin/bash`.

Enter to the containers using their respective `./pgX.sh` scripts to install some prerequisites:

1. Add `postgres` user to sudoers (very handy sometimes).\
   Example (from `pg1` host, as `root` user):
    ```bash
    root@pg1:/# grep sudo /etc/group
    sudo:x:27:ubuntu,postgres
    root@pg1:/#
    ```

<br/>

## Patroni Setup

This section presents the Patroni related setup.

### Patroni installation

On all three `pgX` hosts, run the following commands:

```bash
su - postgres
echo 'export PATH=$PATH:/usr/lib/postgresql/16/bin' > .profile
python3 -m venv patroni-packages
source patroni-packages/bin/activate
pip3 install --upgrade setuptools pip
pip install psycopg[binary] patroni python-etcd
cd patroni-packages
mkdir data && chmod 700 data && cd data
```

In this `data` directory we'll put the Patroni configuration file. So, we'll do it for all three `pgX` hosts in the next steps.

### Patroni configuration

In `pg1` host, put the following into the `patroni.yaml` file:

```yaml
scope: postgres
namespace: Cluster
name: data-pg1
restapi:
    listen: 10.0.0.11:8008
    connect_address: 10.0.0.11:8008
etcd:
    host: 10.0.0.14:2379
bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true
            use_slots: true
            parameters:
    initdb:
        - encoding: UTF8
        - data-checksums
    pg_hba:
        - host replication replicator 127.0.0.1/32 md5
        - host replication replicator 10.0.0.11/0 md5
        - host replication replicator 10.0.0.12/0 md5
        - host replication replicator 10.0.0.13/0 md5
        - host all all 0.0.0.0/0 md5
    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb
postgresql:
    listen: 10.0.0.11:5432
    connect_address: 10.0.0.11:5432
    data_dir: /var/lib/postgresql/patroni-packages/data
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: replicator
            password: '123'
        superuser:
            username: postgres
            password: '123'
    parameters:
        unix_socket_directories: '.'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

In `pg2` host, put the following into the `patroni.yaml` file:

```yaml
scope: postgres
namespace: Cluster
name: data-pg2
restapi:
    listen: 10.0.0.12:8008
    connect_address: 10.0.0.12:8008
etcd:
    host: 10.0.0.14:2379
bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true
            use_slots: true
            parameters:
    initdb:
        - encoding: UTF8
        - data-checksums
    pg_hba:
        - host replication replicator 127.0.0.1/32 md5
        - host replication replicator 10.0.0.11/0 md5
        - host replication replicator 10.0.0.12/0 md5
        - host replication replicator 10.0.0.13/0 md5
        - host all all 0.0.0.0/0 md5
    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb
postgresql:
    listen: 10.0.0.12:5432
    connect_address: 10.0.0.12:5432
    data_dir: /var/lib/postgresql/patroni-packages/data
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: replicator
            password: '123'
        superuser:
            username: postgres
            password: '123'
    parameters:
        unix_socket_directories: '.'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

In `pg3` host, put the following into the `patroni.yaml` file:

```yaml
scope: postgres
namespace: Cluster
name: data-pg3
restapi:
    listen: 10.0.0.13:8008
    connect_address: 10.0.0.13:8008
etcd:
    host: 10.0.0.14:2379
bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true
            use_slots: true
            parameters:
    initdb:
        - encoding: UTF8
        - data-checksums
    pg_hba:
        - host replication replicator 127.0.0.1/32 md5
        - host replication replicator 10.0.0.11/0 md5
        - host replication replicator 10.0.0.12/0 md5
        - host replication replicator 10.0.0.13/0 md5
        - host all all 0.0.0.0/0 md5
    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb
postgresql:
    listen: 10.0.0.13:5432
    connect_address: 10.0.0.13:5432
    data_dir: /var/lib/postgresql/patroni-packages/data
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: replicator
            password: '123'
        superuser:
            username: postgres
            password: '123'
    parameters:
        unix_socket_directories: '.'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

Furthermore, again on all `pgX` hosts, create a minimal `/etc/init.d/patroni` script:

```bash
#!/bin/sh
set -e

case "$1" in
    start)
        su - postgres -c "/var/lib/postgresql/patroni-packages/bin/patroni /var/lib/postgresql/patroni-packages/patroni.yml"
        ;;
    *)
        echo "Usage: /etc/init.d/patroni {start}"
        exit 1
        ;;
esac
exit 0
```

and make it executable using `chmod +x /etc/init.d/patroni`.

TODO: A complete SysV init script would be [this one](https://github.com/patroni/patroni/blob/master/extras/startup-scripts/patroni).

<br/>

## etcd Setup

Start the etcd & HA related container using the `./run_etcdha.sh` script.
Enter the container using `./etcdha.sh` script.

Download [etcd v3.4.32](https://github.com/etcd-io/etcd/releases/download/v3.4.32/etcd-v3.4.32-linux-amd64.tar.gz) and have it extracted into `/apps/etcd` directory.

Start etcd using the following `./etcd --listen-peer-urls="http://10.0.0.14:2380" --listen-client-urls="http://localhost:2379,http://10.0.0.14:2379" --initial-advertise-peer-urls="http://10.0.0.14:2380" --initial-cluster="default=http://10.0.0.14:2380" --advertise-client-urls="http://10.0.0.14:2379" --initial-cluster-token="etcd-cluster" --initial-cluster-state="new" --enable-v2=true`

<br/>

## Start the PostgreSQL HA cluster using Patroni

With `etcd` up and running, start Patroni on all three `pgX` hosts using the `/etc/init.d/patroni start`.

The output on the leader host (which should be `pg1` if we start Patroni on this host first) should be:

```
root@pg1:/etc/init.d# ./patroni start
2025-05-29 14:25:17,437 INFO: No PostgreSQL configuration items changed, nothing to reload.
2025-05-29 14:25:17,442 INFO: Lock owner: None; I am data-pg1
2025-05-29 14:25:17,448 INFO: trying to bootstrap a new cluster
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default text search configuration will be set to "english".

Data page checksums are enabled.

creating directory /var/lib/postgresql/patroni-packages/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/patroni-packages/data -l logfile start

2025-05-29 14:25:22,157 INFO: postmaster pid=131
2025-05-29 14:25:22.160 UTC [131] LOG:  starting PostgreSQL 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0, 64-bit
2025-05-29 14:25:22.160 UTC [131] LOG:  listening on IPv4 address "10.0.0.11", port 5432
2025-05-29 14:25:22.170 UTC [131] LOG:  listening on Unix socket "./.s.PGSQL.5432"
2025-05-29 14:25:22.181 UTC [135] LOG:  database system was shut down at 2025-05-29 14:25:17 UTC
2025-05-29 14:25:22.181 UTC [136] FATAL:  the database system is starting up
10.0.0.11:5432 - rejecting connections
2025-05-29 14:25:22.193 UTC [138] FATAL:  the database system is starting up
10.0.0.11:5432 - rejecting connections
2025-05-29 14:25:22.194 UTC [131] LOG:  database system is ready to accept connections
10.0.0.11:5432 - accepting connections
2025-05-29 14:25:23,208 INFO: establishing a new patroni heartbeat connection to postgres
2025-05-29 14:25:23,219 INFO: running post_bootstrap
2025-05-29 14:25:23,228 ERROR: User creation is not be supported starting from v4.0.0. Please use "bootstrap.post_bootstrap" script to create users.
2025-05-29 14:25:23,228 WARNING: Could not activate Linux watchdog device: Can't open watchdog device: [Errno 2] No such file or directory: '/dev/watchdog'
2025-05-29 14:25:23,236 INFO: initialized a new cluster
2025-05-29 14:25:33,238 INFO: no action. I am (data-pg1), the leader with the lock
2025-05-29 14:25:43,242 INFO: no action. I am (data-pg1), the leader with the lock
2025-05-29 14:25:53,238 INFO: no action. I am (data-pg1), the leader with the lock
```

On `pg2` host, the output would be like this:

```
postgres@pg2:~$ sudo /etc/init.d/patroni start
2025-05-29 14:27:54,540 INFO: No PostgreSQL configuration items changed, nothing to reload.
2025-05-29 14:27:54,543 INFO: Lock owner: data-pg1; I am data-pg2
2025-05-29 14:27:54,545 INFO: trying to bootstrap from leader 'data-pg1'
WARNING:  skipping special file "./.s.PGSQL.5432"
WARNING:  skipping special file "./.s.PGSQL.5432"
2025-05-29 14:28:03,239 INFO: replica has been created using basebackup
2025-05-29 14:28:03,239 INFO: bootstrapped from leader 'data-pg1'
2025-05-29 14:28:03.397 UTC [63] LOG:  starting PostgreSQL 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0, 64-bit
2025-05-29 14:28:03.397 UTC [63] LOG:  listening on IPv4 address "10.0.0.12", port 5432
2025-05-29 14:28:03,400 INFO: postmaster pid=63
2025-05-29 14:28:03.407 UTC [63] LOG:  listening on Unix socket "./.s.PGSQL.5432"
2025-05-29 14:28:03.418 UTC [67] LOG:  database system was interrupted; last known up at 2025-05-29 14:27:59 UTC
2025-05-29 14:28:03.418 UTC [68] FATAL:  the database system is starting up
10.0.0.12:5432 - rejecting connections
2025-05-29 14:28:03.429 UTC [70] FATAL:  the database system is starting up
10.0.0.12:5432 - rejecting connections
2025-05-29 14:28:03.882 UTC [67] LOG:  entering standby mode
2025-05-29 14:28:03.882 UTC [67] LOG:  starting backup recovery with redo LSN 0/2000028, checkpoint LSN 0/2000060, on timeline ID 1
2025-05-29 14:28:03.893 UTC [67] LOG:  redo starts at 0/2000028
2025-05-29 14:28:03.897 UTC [67] LOG:  completed backup recovery with redo LSN 0/2000028 and end LSN 0/2000100
2025-05-29 14:28:03.897 UTC [67] LOG:  consistent recovery state reached at 0/2000100
2025-05-29 14:28:03.897 UTC [63] LOG:  database system is ready to accept read-only connections
2025-05-29 14:28:03.907 UTC [71] LOG:  started streaming WAL from primary at 0/3000000 on timeline 1
10.0.0.12:5432 - accepting connections
2025-05-29 14:28:04,446 INFO: Lock owner: data-pg1; I am data-pg2
2025-05-29 14:28:04,446 INFO: establishing a new patroni heartbeat connection to postgres
2025-05-29 14:28:04,491 INFO: no action. I am (data-pg2), a secondary, and following a leader (data-pg1)
2025-05-29 14:28:13,247 INFO: no action. I am (data-pg2), a secondary, and following a leader (data-pg1)
2025-05-29 14:28:23,247 INFO: no action. I am (data-pg2), a secondary, and following a leader (data-pg1)
2025-05-29 14:28:33,246 INFO: no action. I am (data-pg2), a secondary, and following a leader (data-pg1)
```

On `pg3` host, the output would be like this:

```
postgres@pg3:~$ sudo /etc/init.d/patroni start
[sudo] password for postgres:
2025-05-29 14:29:15,357 INFO: No PostgreSQL configuration items changed, nothing to reload.
2025-05-29 14:29:15,360 INFO: Lock owner: data-pg1; I am data-pg3
2025-05-29 14:29:15,362 INFO: trying to bootstrap from leader 'data-pg1'
WARNING:  skipping special file "./.s.PGSQL.5432"
WARNING:  skipping special file "./.s.PGSQL.5432"
2025-05-29 14:29:19,496 INFO: replica has been created using basebackup
2025-05-29 14:29:19,497 INFO: bootstrapped from leader 'data-pg1'
2025-05-29 14:29:19,651 INFO: postmaster pid=407
2025-05-29 14:29:19.653 UTC [407] LOG:  starting PostgreSQL 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0, 64-bit
2025-05-29 14:29:19.653 UTC [407] LOG:  listening on IPv4 address "10.0.0.13", port 5432
2025-05-29 14:29:19.663 UTC [407] LOG:  listening on Unix socket "./.s.PGSQL.5432"
2025-05-29 14:29:19.674 UTC [411] LOG:  database system was interrupted; last known up at 2025-05-29 14:29:15 UTC
2025-05-29 14:29:19.674 UTC [412] FATAL:  the database system is starting up
10.0.0.13:5432 - rejecting connections
2025-05-29 14:29:19.686 UTC [414] FATAL:  the database system is starting up
10.0.0.13:5432 - rejecting connections
2025-05-29 14:29:20.122 UTC [411] LOG:  entering standby mode
2025-05-29 14:29:20.122 UTC [411] LOG:  starting backup recovery with redo LSN 0/4000028, checkpoint LSN 0/4000060, on timeline ID 1
2025-05-29 14:29:20.133 UTC [411] LOG:  redo starts at 0/4000028
2025-05-29 14:29:20.137 UTC [411] LOG:  completed backup recovery with redo LSN 0/4000028 and end LSN 0/4000100
2025-05-29 14:29:20.137 UTC [411] LOG:  consistent recovery state reached at 0/4000100
2025-05-29 14:29:20.137 UTC [407] LOG:  database system is ready to accept read-only connections
2025-05-29 14:29:20.146 UTC [415] FATAL:  could not start WAL streaming: ERROR:  replication slot "data_pg3" does not exist
2025-05-29 14:29:20.151 UTC [416] FATAL:  could not start WAL streaming: ERROR:  replication slot "data_pg3" does not exist
2025-05-29 14:29:20.151 UTC [411] LOG:  waiting for WAL to become available at 0/5000018
10.0.0.13:5432 - accepting connections
2025-05-29 14:29:20,702 INFO: Lock owner: data-pg1; I am data-pg3
2025-05-29 14:29:20,702 INFO: establishing a new patroni heartbeat connection to postgres
2025-05-29 14:29:20,774 INFO: no action. I am (data-pg3), a secondary, and following a leader (data-pg1)
2025-05-29 14:29:23,250 INFO: no action. I am (data-pg3), a secondary, and following a leader (data-pg1)
2025-05-29 14:29:25.156 UTC [423] LOG:  started streaming WAL from primary at 0/5000000 on timeline 1
2025-05-29 14:29:33,250 INFO: no action. I am (data-pg3), a secondary, and following a leader (data-pg1)
2025-05-29 14:29:43,253 INFO: no action. I am (data-pg3), a secondary, and following a leader (data-pg1)
2025-05-29 14:29:53,251 INFO: no action. I am (data-pg3), a secondary, and following a leader (data-pg1)
```

### Checking the result

If everything went ok, besides the output above, we can ask Patroni to get us a status like this:

```bash
postgres@pg1:~/patroni-packages/bin$ ./patronictl -c ~/patroni-packages/patroni.yml list
+ Cluster: postgres (7509873657610391674) ---+----+-----------+
| Member   | Host      | Role    | State     | TL | Lag in MB |
+----------+-----------+---------+-----------+----+-----------+
| data-pg1 | 10.0.0.11 | Leader  | running   |  1 |           |
| data-pg2 | 10.0.0.12 | Replica | streaming |  1 |         0 |
| data-pg3 | 10.0.0.13 | Replica | streaming |  1 |         0 |
+----------+-----------+---------+-----------+----+-----------+
postgres@pg1:~/patroni-packages/bin$
```

And we can see what's happening on `etc` side as well by using the following commands on `etcdha` host:

```bash
export ETCDCTL_API=2                              # Since `--enable-v2` and version 3.4 is used.
/apps/etcd/etcdctl ls -r /Cluster/postgres        # To get the keys that Patroni uses.
/apps/etcd/etcdctl watch -r -f /Cluster/postgres  # To watch how Patroni keys are updated over (in real) time.
```

<br/>

## HAProxy Setup

Still on `etcdha` host, let's first install HAProxy using `apt update && apt install -y haproxy`.

Put the following content in `/etc/haproxy/haproxy.cfg` file:

```cfg
global
        log /dev/log    local0
        log /dev/log    local1 notice
        log 127.0.0.1   local2
        maxconn 100
defaults
        log global
        mode tcp
        retries 2
        timeout client 30m
        timeout connect 4s
        timeout server 30m
        timeout check 5s
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /
listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 10.0.0.11:5432 maxconn 100 check port 8008
    server node2 10.0.0.12:5432 maxconn 100 check port 8008
    server node3 10.0.0.13:5432 maxconn 100 check port 8008
```

And start HAProxy using `/etc/init.d/haproxy start`.

<br/>

## pgBackRest Setup

### Passwordless (SSH based) Authentication

#### Generate SSH keys

-   Enter into the container (using `./pg1.sh`, for example).
-   Switch to `postgres` user (using `su - postgres`).
-   Generate the keypair (using `ssh-keygen -t rsa`).

#### Copy the public keys to each others hosts

Copy the public key (from `~/.ssh/id_rsa.pub`) of `postgres` user from one host to the other\
(into `~/.ssh/authorized_keys` file of `postgres` user on that host).\
A shorter way is to use `ssh-copy-id` command (such as `ssh-copy-id pg2`)\
which copies the public key of `postgres` user from `pg1` to `pg2`.

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
