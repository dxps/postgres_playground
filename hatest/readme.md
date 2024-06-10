## PostgreSQL High Availability Test using a Patroni based setup

Based on Patroni's `HAtester.py` script, made some changes to fit my needs (better error handling, no ctrl+c capture to reconnect).

<br/>

### Prerequisites

-   Run `sudo apt install python3-dev libpq-dev`
-   Run `python -m pip install python-dotenv psycopg2` to install the modules needed by the scripts.

Also `patronictl` tool must be available if you want to watch the cluster state, as reported by Patroni, using `./watch_patroni.sh`.

<br/>

### Setup

Run the following entries on primary / leader host by connecting to postgres database using a user with enough privileges:

```sql
CREATE USER hatest WITH ENCRYPTED PASSWORD 'hatest';
CREATE DATABASE hatest OWNER hatest;
```

Next, to test the result, plus continue with the rest of the needed objects, connect to the same primary / leader host using `hatest` user
and run:

```sql
CREATE TABLE HATEST (TM TIMESTAMP);
CREATE UNIQUE INDEX idx_hatest ON hatest (tm desc);
```

Now you should be able to connect to `hatest` database on any of the replica hosts using `hatest` user
and see all the objects that were previously created on the primary / leader host
(that is the `hatest` table on `public` schema and the `idx_hatest` index on that table).

<br/>

### Usage

#### Watch cluster state

On any two hosts (regardless of their role, as either _Leader_ or _Replica_), run `./watch_patroni.sh` provided script to see the cluster state. The output should look like this:

```
+ Cluster: cluster_1 (7368382315229381771) -+-----------+----+-----------+-----------------+------------------------+-------------------+------+
| Member            | Host        | Role    | State     | TL | Lag in MB | Pending restart | Pending restart reason | Scheduled restart | Tags |
+-------------------+-------------+---------+-----------+----+-----------+-----------------+------------------------+-------------------+------+
| my-pgdb-ha-host-1 | 10.11.12.13 | Leader  | running   |  4 |           |                 |                        |                   |      |
| my-pgdb-ha-host-2 | 10.11.12.14 | Replica | streaming |  4 |         0 |                 |                        |                   |      |
| my-pgdb-ha-host-3 | 10.11.12.15 | Replica | streaming |  4 |         0 |                 |                        |                   |      |
+-------------------+-------------+---------+-----------+----+-----------+-----------------+------------------------+-------------------+------+

```

#### Read data on a replica host

-   Create the `hatest_reader_replica.env` file with your connection details,\
    based on the provided `hatest_reader_replica.env.sample` file.
-   Start the reader using `./hatest_reader_replica.py`

#### Write data on the leader host

-   Create the `hatest_writer_primary.env` file with your connection details,\
    based on the provided `hatest_writer_primary.env.sample` file.
-   Start the writer using `./hatest_writer_primary.py`
