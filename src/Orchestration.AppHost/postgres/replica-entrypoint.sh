#!/bin/bash
# On first start (no standby.signal), clones the primary via pg_basebackup.
# On subsequent starts, resumes streaming replication from existing PGDATA.
# Retries until the primary is accepting replication connections.
set -e
export PGDATA=/var/lib/postgresql/data

# standby.signal is a zero-byte marker file — test for existence (-e), not
# non-empty content (-s), or every restart would re-clone from scratch.
if [ ! -e "$PGDATA/standby.signal" ]; then
  echo "replica: cloning primary via pg_basebackup..."
  mkdir -p "$PGDATA"
  rm -rf "$PGDATA"/*
  until PGPASSWORD="$POSTGRES_PASSWORD" pg_basebackup \
    -h host.docker.internal -p 5432 -U postgres \
    -D "$PGDATA" -Fp -Xs -R -w -P; do
    echo "replica: primary not ready, retrying in 2s..."
    sleep 2
  done
  chown -R postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"
fi

exec gosu postgres postgres
