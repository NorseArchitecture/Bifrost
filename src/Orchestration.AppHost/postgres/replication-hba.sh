#!/bin/bash
# Appended by initdb to pg_hba.conf on the primary's first start.
# Allows pg_basebackup on the replica to connect via scram-sha-256.
# Runs once (/docker-entrypoint-initdb.d/); the server reads the updated
# pg_hba.conf on start after initdb completes.
#
# Note: pg_hba.conf "all" in the database column does NOT match the special
# "replication" pseudo-database — an explicit "replication" entry is required.
set -e
cat >> "$PGDATA/pg_hba.conf" <<'EOF'
host replication all all scram-sha-256
EOF
