#!/usr/bin/env bash

service postgresql start
echo "$DB_HOSTNAME:$PORT:*:$USERNAME:$PASSWORD"
echo "$DB_HOSTNAME:$PORT:*:$USERNAME:$PASSWORD" > ~/.pgpass
chmod 600 ~/.pgpass
# psql -U $USERNAME -h $DB_HOSTNAME -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND datname='app_rent_staging"
dropdb -w -U $USERNAME -h $DB_HOSTNAME $DATABASE
createdb -w -U $USERNAME -h $DB_HOSTNAME $DATABASE
pg_restore --no-owner --role=$USERNAME -h $DB_HOSTNAME -d $DATABASE -U $USERNAME -Fc -1 db.dump