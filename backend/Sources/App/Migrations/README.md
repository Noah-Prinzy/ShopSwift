# Why this folder has no Fluent schema migrations

Phase 1 uses **Flyway** as the database schema owner so that every schema change is visible as SQL.

Migration files live in:

`backend/Resources/db/migration/`

- `V1__initial_schema.sql`
- `V2__seed_products.sql`

Fluent models under `Sources/App/Models` map onto those tables at runtime; they do not auto-create the schema.
