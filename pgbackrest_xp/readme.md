The `openssh-server` image is taken from [here](https://hub.docker.com/r/linuxserver/openssh-server).

<br/>

### Install prerequisites

1. Besides some needed classic utilities such as `sudo` and `vim` (installed using `apt update` (really needed, first time) and then `apt install vim sudo`), install PostgreSQL server and client using `apt install postgresql-16`.
2. Add `postgres` user to sudoers (it's just a helpful thing). Example (from `pg1` host):
    ```shell
    root@pg1:/# grep sudo /etc/group
    sudo:x:27:ubuntu,postgres
    root@pg1:/#
    ```

<br/>

### Passwordless (SSH based) Authentication

#### Generate SSH keys

-   Enter into the container (`docker exec -it pg1 /bin/bash`)
-   Switch to `postgres` user (`su - postgres`)
-   Generate the keypar (`ssh-keygen -t rsa`)

#### Copy the public keys to each others hosts

-   Copy the public key (from `~/.ssh/id_rsa.pub`) of `postgres` user from one host to the other (into `~/.ssh/authorized_keys` file of `postgres` user on that host).

<br/>

### Connect to nodes

`ssh postgres@localhost -p 2221`

<br/>

### Init the secondary server

On `pg2` host, do:

1. Remove the existing data directory (`rm -rf /var/lib/postgresql/16/main/`)
2. Run `pg_basebackup -h pg1 -w -U postgres -F plain -X stream -R -S dxps_slot -C -D /var/lib/postgresql/16/main/` to copy the data from `pg1` to `pg2`.
