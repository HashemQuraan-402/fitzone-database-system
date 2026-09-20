# FitZone Database System

A PostgreSQL portfolio project for gym membership, trainers, classes, scheduled sessions, bookings, reporting, PL/pgSQL automation, security roles, and auditing.

## What is included

- Normalized relational schema with keys, constraints, and indexes
- Repeatable sample data
- Ten reporting and analytics queries
- SQL and PL/pgSQL functions
- Safe booking and member-status procedures
- Capacity, rating, loyalty, and audit triggers
- Least-privilege role example with runtime password prompts
- Transactional manual smoke tests
- Schema diagram in `docs/fitzone-schema-diagram.png`

## Database schema

![FitZone PostgreSQL database schema](docs/fitzone-schema-diagram.png)

## Requirements

PostgreSQL and the `psql` command-line client.

## Create and load the database

From this repository root:

```powershell
createdb fitzone_db
psql -v ON_ERROR_STOP=1 -d fitzone_db -f sql/01_schema.sql
psql -v ON_ERROR_STOP=1 -d fitzone_db -f sql/02_seed_data.sql
psql -v ON_ERROR_STOP=1 -d fitzone_db -f sql/04_functions_and_triggers.sql
```

Run the portfolio queries:

```powershell
psql -d fitzone_db -f sql/03_queries.sql
```

Run smoke tests; they finish with `ROLLBACK` and leave the sample data unchanged:

```powershell
psql -v ON_ERROR_STOP=1 -d fitzone_db -f tests/manual_tests.sql
```

To rebuild from scratch, rerun the numbered files beginning with `01_schema.sql`. That file intentionally drops and recreates only this project's tables.

## Optional role example

Review `sql/05_roles.example.sql`, connect as a PostgreSQL administrator, and run:

```powershell
psql -v ON_ERROR_STOP=1 -d fitzone_db -f sql/05_roles.example.sql
```

The script prompts for passwords instead of committing them. Adapt database and role names before using it outside a local demonstration.

## File order

1. `01_schema.sql`
2. `02_seed_data.sql`
3. `03_queries.sql` (read-only examples)
4. `04_functions_and_triggers.sql`
5. `05_roles.example.sql` (optional administrator task)

## Security

Never commit database passwords, `.pgpass`, connection URLs, or database dumps containing personal data. Use separate roles and secrets for production, review grants, encrypt connections, and back up before running destructive schema scripts.

