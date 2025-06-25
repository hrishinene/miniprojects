#!/bin/bash

# Variables
PGUSER=postgres  # Default PostgreSQL user
PGPASSWORD=unplugged
PGHOST=localhost
PGPORT=5432
TARGET_DB=postgres  # Default DB to connect to
NEW_DB=DB1

# Export environment variables
export PGPASSWORD

# Run the SQL command
# drop database if exists DB1 forcefully
psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$TARGET_DB" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$NEW_DB' AND pid <> pg_backend_pid();"
psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$TARGET_DB" -c "DROP DATABASE IF EXISTS \"$NEW_DB\";"

# Create the new database
psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$TARGET_DB" -c "CREATE DATABASE \"$NEW_DB\";"
if [ $? -eq 0 ]; then
    echo "Database '$NEW_DB' created successfully."
else
    echo "Failed to create database '$NEW_DB'."
    exit 1
fi

cd ../../src/schema
# Run the schema initialization script
psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$NEW_DB" -f ../../src/schema/schema.sql
if [ $? -eq 0 ]; then
    echo "Schema initialized successfully in database '$NEW_DB'."
else
    echo "Failed to initialize schema in database '$NEW_DB'."
    exit 1
fi