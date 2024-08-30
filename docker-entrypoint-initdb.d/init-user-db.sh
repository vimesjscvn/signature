#!/bin/bash
set -e

# Ensure log directory exists and has correct permissions
mkdir -p /var/lib/postgresql/data/pg_log
chmod -R 755 /var/lib/postgresql/data/pg_log

# Redirect all output to log file
exec > >(tee -a /var/lib/postgresql/data/pg_log/init-user-db.log) 2>&1

# Define database name and SQL file
DATABASE_NAME="sign.pro"
SQL_FILE="/docker-entrypoint-initdb.d/sign.pro.sql"

# Wait for PostgreSQL to be ready
until psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" -c "select 1" > /dev/null 2>&1; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

echo "PostgreSQL is ready."

# Check if the database already exists
DB_EXISTS=$(psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DATABASE_NAME'")
if [ "$DB_EXISTS" == "1" ]; then
    echo "Database $DATABASE_NAME already exists, dropping it..."

    # Disconnect all users
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<EOSQL
REVOKE CONNECT ON DATABASE "$DATABASE_NAME" FROM public;
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DATABASE_NAME'
  AND pid <> pg_backend_pid();
EOSQL
    
    # Drop the database
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<EOSQL
DROP DATABASE "$DATABASE_NAME";
EOSQL
    echo "Database $DATABASE_NAME dropped."
fi

echo "Creating database $DATABASE_NAME..."

# Create the database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<EOSQL
CREATE DATABASE "$DATABASE_NAME";
GRANT ALL PRIVILEGES ON DATABASE "$DATABASE_NAME" TO "$POSTGRES_USER";
EOSQL

echo "Database $DATABASE_NAME created and privileges granted."

# Wait a bit to ensure the database is fully initialized
sleep 5

echo "Restoring database $DATABASE_NAME from $SQL_FILE..."
pg_restore -v --no-owner -U "$POSTGRES_USER" -d "$DATABASE_NAME" "$SQL_FILE"
echo "Database $DATABASE_NAME restored from $SQL_FILE."