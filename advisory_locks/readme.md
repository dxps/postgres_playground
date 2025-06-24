## PostgreSQL Advisory Locks sample

Just a sample of using PostgreSQL's advisory locks feature.

The code is mainly taken from [here](https://github.com/hay-kot/examples-pg-locking/tree/main) and it has a nice [article](https://haykot.dev/blog/distributed-locking-with-postgre-sql/) on this feature.

<br/>

### Usage

1. Either start a local PostgreSQL instance as a Docker container or use an existing instance and update [main.go](./main.go) file's `dbString` (line 31) with the corresponding database connection details.
    - To start a local PostgreSQL instance, do:
        - `cd ops`
        - `./run_db_server.sh`
2. Run the sample using `go run main.go`
