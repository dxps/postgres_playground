#!/bin/sh

usage() {
  echo 
  echo " Error: No migration version provided."
  echo " Hints: Look into ./ops/db_migrations folder and see the latest version."
  echo "        For example, if the most recent file starts with 000003, then use ./run_db_migrations.sh 3"
  echo " Usage:"
  echo "   - Migrate to a specific version using ./run_db_migrations.sh {version}"
  echo "   - Force migrating (after fixing the errors) to a specific version using ./run_db_migrations.sh {version} force"
  echo 
  exit 1
}

if [ "$#" -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "-help" ]; then
  usage
  exit 1
fi

DB_DSN="postgres://optimistic_locking:optimistic_locking@localhost:5457/optimistic_locking?sslmode=disable"
CURR_DIR=`dirname "$0"`
VERSION=$1

echo 
echo "Running migrate with DB_DSN=$DB_DSN and VERSION=$VERSION"
echo 
if [ "$#" -eq 1 ]; then
  migrate -path=${CURR_DIR}/db_migrations -database=$DB_DSN goto $1
elif [ "$#" -eq 2 ] && [ "$2" = "force" ]; then
  migrate -path=${CURR_DIR}/db_migrations -database=$DB_DSN force $1
else
  usage
fi
