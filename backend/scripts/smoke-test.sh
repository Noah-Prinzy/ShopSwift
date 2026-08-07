#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
STAMP="$(date +%s)"
EMAIL="phase1-${STAMP}@example.com"
USERNAME="phase1-${STAMP}"

# 1) Confirm the server is alive.
curl -fsS "$BASE_URL/health"; echo

# 2) Create a unique account and extract the returned bearer token.
AUTH="$(curl -fsS -X POST "$BASE_URL/api/v1/auth/signup" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"password123\"}")"
TOKEN="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<< "$AUTH")"

# 3) Read products, then add the known seeded phone product to the cart.
curl -fsS "$BASE_URL/api/v1/products" > /dev/null
curl -fsS -X POST "$BASE_URL/api/v1/cart/items" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"productID":"10000000-0000-0000-0000-000000000001","quantity":1}'; echo

# 4) Checkout demonstrates a complete database-backed shopping loop.
curl -fsS -X POST "$BASE_URL/api/v1/orders/checkout" -H "Authorization: Bearer $TOKEN"; echo
echo "Phase 1 smoke test passed for $EMAIL"
