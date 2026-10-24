# house-rental-management

## Local database: legacy V7 checksum mismatch

If startup fails with `Migration checksum mismatch for migration version 7`
(`Applied: -1427746094`, `Resolved: -602544506`), the local database still
records the checksum of the legacy V7 source. The repository contains a
reconstructed V7 migration for the existing `user_favorites` schema.

Back up the database with `pg_dump` before recovery, then run from the
repository root (provide the database password when prompted):

```powershell
pg_dump -h 127.0.0.1 -p 5433 -U postgres -d rental_management_db -Fc -f backend/local-backups/before-v7-repair.dump
if ($LASTEXITCODE -ne 0) { throw 'Backup failed; stop recovery' }
psql -h 127.0.0.1 -p 5433 -U postgres -d rental_management_db -X -v ON_ERROR_STOP=1 -f backend/scripts/repair-legacy-v7-checksum.sql
if ($LASTEXITCODE -ne 0) { throw 'Recovery failed; inspect the database schema' }
```

Use the PostgreSQL tools' full paths if they are not on `PATH`.
The recovery script checks the legacy checksum, columns, unique constraint,
and foreign keys before updating only the V7 history checksum in a transaction.
It does not modify application rows. It is a one-time recovery for this exact
legacy database state; do not run it for other checksum mismatches.

Restart the backend. Flyway should validate successfully and report schema
version 11 (or a later version after future migrations). Keep Flyway validation
enabled and add new migrations for subsequent schema changes instead of
editing migrations already applied to a database.
