#!/usr/bin/env bash

service postgresql start
echo "$DB_HOSTNAME:$PORT:$DATABASE:$USERNAME:$PASSWORD" > ~/.pgpass
chmod 600 ~/.pgpass
pg_dump -x -Fc $DATABASE -U $USERNAME -h $DB_HOSTNAME > db.dump
zip db.dump.zip db.dump