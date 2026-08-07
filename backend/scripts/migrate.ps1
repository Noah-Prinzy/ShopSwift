# Starts PostgreSQL and applies every pending Flyway migration on Windows/PowerShell.
docker compose up -d postgres
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
docker compose run --rm flyway
