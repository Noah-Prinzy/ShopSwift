#!/usr/bin/env bash
set -euo pipefail

# ShopSwift container startup
# - Applies the versioned Flyway migrations against the configured PostgreSQL database.
# - Starts Vapor using the environment-specific HOST/PORT values.
# Flyway remains the only schema owner; running migrate repeatedly is safe because
# previously applied versions are recorded in flyway_schema_history.

DATABASE_HOST="${DATABASE_HOST:-localhost}"
DATABASE_PORT="${DATABASE_PORT:-5432}"
DATABASE_NAME="${DATABASE_NAME:-shopswift_db}"
DATABASE_USERNAME="${DATABASE_USERNAME:-shopswift_user}"
DATABASE_PASSWORD="${DATABASE_PASSWORD:-change_me}"
APP_ENV="${APP_ENV:-production}"

# Hosted providers commonly expose a libpq-style connection string such as:
# postgresql://user:password@host:5432/database
# Vapor can consume DATABASE_URL directly. Flyway needs JDBC syntax, so strip the
# credential prefix from the URL and pass the credentials separately.
if [[ -n "${DATABASE_URL:-}" ]]; then
  database_target="${DATABASE_URL#*://}"
  database_target="${database_target#*@}"
  FLYWAY_URL="jdbc:postgresql://${database_target}"
else
  FLYWAY_URL="jdbc:postgresql://${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}"
fi

printf 'Applying ShopSwift database migrations...\n'
flyway \
  -url="${FLYWAY_URL}" \
  -user="${DATABASE_USERNAME}" \
  -password="${DATABASE_PASSWORD}" \
  -locations="filesystem:/app/Resources/db/migration" \
  -connectRetries=20 \
  migrate

printf 'Starting ShopSwift Vapor server in %s mode...\n' "${APP_ENV}"
exec ./Run serve --env "${APP_ENV}"
