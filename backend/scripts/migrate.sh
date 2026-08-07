#!/usr/bin/env bash
set -euo pipefail
# Starts PostgreSQL and applies every pending Flyway migration.
docker compose up -d postgres
docker compose run --rm flyway
