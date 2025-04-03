#!/bin/bash

cat << EOF > /docker-entrypoint-initdb.d/init.sql
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
