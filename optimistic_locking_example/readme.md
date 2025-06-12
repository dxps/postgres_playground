## Optimistic Locking

This is an example of implementing optimistic locking in PostgreSQL, although the implementation is database agnostic.

The `./cmd/verfacts_run/main.go` program uses a configurable number of workers (see `./internal/config/config.go` and `./.env` file) to concurrently insert and update the `verfacts` table by:

1. Doing an insert.
2. Doing an update on a randomly selected row.\
   That's why only some of the rows get updated and for all the other an error is logged\
   See those "no rows updates" related errors in the execution output.

<br/>

### Setup

Either use your own PostgreSQL database (and update the connection settings in `./internal/config/config.go`) or start a PostgreSQL container on your local machine by running:

```shell
cd ops
./run_db_server.sh
./run_db_migrations.sh
```

<br/>

### Usage

Run `go run ./cmd/verfacts_run/main.go`.
The output will look something like this:

```
❯ go run cmd/verfacts_run/main.go
time=2025-06-12T18:27:36.051+03:00 level=INFO source=main.go:32 msg="Starting up ..."
time=2025-06-12T18:27:36.051+03:00 level=INFO source=main.go:38 msg="Config loaded. Using 10 workers."
time=2025-06-12T18:27:36.051+03:00 level=INFO source=main.go:39 msg="Connecting to database ..."
time=2025-06-12T18:27:36.055+03:00 level=INFO source=main.go:49 msg="Successfully connected to database."
time=2025-06-12T18:27:36.055+03:00 level=INFO source=main.go:63 msg="Waiting for workers to finish ..."
time=2025-06-12T18:27:36.061+03:00 level=ERROR source=main.go:58 msg="Worker 4 failed with '[worker 4] SetAsProcessed failed with 'no rows updated''."
time=2025-06-12T18:27:36.062+03:00 level=ERROR source=main.go:58 msg="Worker 10 failed with '[worker 10] SetAsProcessed failed with 'no rows updated''."
time=2025-06-12T18:27:36.063+03:00 level=ERROR source=main.go:58 msg="Worker 2 failed with '[worker 2] SetAsProcessed failed with 'no rows updated''."
time=2025-06-12T18:27:36.063+03:00 level=ERROR source=main.go:58 msg="Worker 6 failed with '[worker 6] SetAsProcessed failed with 'no rows updated''."
time=2025-06-12T18:27:36.067+03:00 level=ERROR source=main.go:58 msg="Worker 7 failed with '[worker 7] SetAsProcessed failed with 'no rows updated''."
time=2025-06-12T18:27:36.067+03:00 level=INFO source=main.go:65 msg="All workers finished."
❯
```

and as per previous execution, the `verfacts` table gets populated like this:

```sql
id|state|processed|version|
--+-----+---------+-------+
 4|I    |false    |      1|
10|I    |false    |      1|
 2|I    |false    |      1|
 8|I    |false    |      1|
 3|I    |false    |      1|
 6|I    |true     |      2|
 5|I    |true     |      2|
 7|I    |true     |      2|
 9|I    |true     |      2|
 1|I    |true     |      2|
```
