#!/bin/sh
set -e

# Variables
DATABASE_NAME="${POSTGRES_DB}"
SQL_FILE="/reset.sql"
LOG_FILE="/var/log/cron_job.log"
DB_HOST="pgdatabase"

# Run the SQL script and log output
{
  echo "[$(date)] Starting backup and reset process..."
  PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${DB_HOST} -U ${POSTGRES_USER} -d ${DATABASE_NAME} -f ${SQL_FILE}
  echo "[$(date)] Backup and reset completed successfully."
} >> ${LOG_FILE} 2>&1