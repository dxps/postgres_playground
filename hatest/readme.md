## PostgreSQL High Availability Test using a Patroni based setup

Based on Patroni's `HAtester.py` script, made some changes to fit my needs (better error handling, no ctrl+c capture to reconnect).

<br/>

### Prerequisites

-   Run `sudo apt install python3-dev libpq-dev`
-   Run `python -m pip install python-dotenv psycopg2` to install the modules needed by the scripts.

Also `patronictl` tool must be available if you want to watch the cluster state, as reported by Patroni, using `./watch_patroni.sh`.

<br/>

### Usage

#### Watch cluster state

On any two hosts (regardless of their role, as either _Leader_ or _Replica_), run `./watch_patroni.sh` provided script to see the cluster state. The output should look like this:

```
+ Cluster: cluster_1 (7368382315229381771) -+-----------+----+-----------+-----------------+------------------------+-------------------+------+
| Member            | Host        | Role    | State     | TL | Lag in MB | Pending restart | Pending restart reason | Scheduled restart | Tags |
+-------------------+-------------+---------+-----------+----+-----------+-----------------+------------------------+-------------------+------+
| my-pgdb-ha-host-1 | 10.63.85.25 | Leader  | running   |  4 |           |                 |                        |                   |      |
| my-pgdb-ha-host-2 | 10.63.85.26 | Replica | streaming |  4 |         0 |                 |                        |                   |      |
| my-pgdb-ha-host-3 | 10.63.85.27 | Replica | streaming |  4 |         0 |                 |                        |                   |      |
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
