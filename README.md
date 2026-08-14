# ShopSwift — Phase 1

A working shopping prototype architecture built around **SwiftUI + Vapor + PostgreSQL + Flyway**.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/Noah-Prinzy/ShopSwift)

> **Production deployment:** the Render Blueprint in `render.yaml` creates the public Vapor web service and PostgreSQL 18 database together. Vapor also serves the PWA from `backend/Public`, so the Render service URL can run the complete ShopSwift prototype on one origin while the Vercel frontend is being connected to that backend.

## Phase 1 features

- Account signup with unique username + unique email + password
- Login only for registered users
- Bcrypt password hashing
- Bearer-token authentication with 7-day token expiry
- Logout
- Profile read/update (username + email)
- Password change (invalidates old sessions)
- Product catalog, categories and search
- Cart add/update/remove/clear
- Prototype checkout
- Order history API
- PostgreSQL runtime persistence through Fluent
- Versioned Flyway SQL migrations
- Seeded electronics catalog
- SwiftUI frontend wired to the REST backend
- Basic installable PWA demo served by Vapor and wired to the same API

## Architecture

```text
ShopSwift/
├── backend/
│   ├── Package.swift
│   ├── docker-compose.yml
│   ├── Public/                       # browser PWA shell
│   ├── Resources/db/migration/       # Flyway SQL
│   ├── Sources/App/
│   │   ├── Configuration/
│   │   ├── Controllers/              # REST route logic
│   │   ├── DTOs/                     # request/response payloads
│   │   ├── Database/                 # Fluent/PostgreSQL configuration
│   │   ├── Middleware/
│   │   ├── Models/                   # Fluent models
│   │   └── Routes/
│   ├── Sources/Run/                  # executable entry point
│   └── Tests/
├── frontend/
│   ├── App/                          # SwiftUI app entry/navigation
│   ├── Core/                         # models, API client, session, services
│   ├── Features/                     # authentication, products, cart, profile
│   └── Shared/
└── shared/APIContracts/              # endpoint documentation
```

## Why REST for Phase 1?

The current flows are resource-oriented and request/response based: signup, login, profile edits, catalog reads, cart mutations and checkout. REST is simpler to build, test and explain for these operations. WebSockets are intentionally deferred until there is a real-time requirement such as live delivery tracking, support chat, stock broadcasts or instant order-status notifications.

## Database + Flyway

Flyway owns the schema. Fluent does **not** create tables automatically in this project.

- `V1__initial_schema.sql` creates users, tokens, products, carts and orders.
- `V2__seed_products.sql` inserts a small electronics catalog.
- Flyway records applied migrations in `flyway_schema_history`.

This split is useful in a supervised prototype because the SQL history is explicit while Vapor still gets a type-safe ORM at runtime.

## Developer notes: inline comments added

- Short, explanatory comments were added to backend controllers (`Sources/App/Controllers/*`), database configuration and Flyway migrations under `backend/Resources/db/migration/`.
- Frontend SwiftUI views in `frontend/Features/` (Products, Cart, Authentication) now contain brief notes describing their network/load behavior and main actions.

These comments are designed to be concise and helpful during code review or onboarding.

## Fast local startup with Docker

From `backend/`:

### 1. Create your environment file

macOS/Linux:

```bash
cp .env.example .env
```

PowerShell:

```powershell
Copy-Item .env.example .env
```

For local prototype use you may keep the example values. Change the password before any public deployment.

### 2. Start PostgreSQL + migrate

macOS/Linux:

```bash
./scripts/migrate.sh
```

PowerShell:

```powershell
./scripts/migrate.ps1
```

Equivalent manual commands:

```bash
docker compose up -d postgres
docker compose run --rm flyway
```

### 3. Run Vapor

```bash
swift run Run
```

The API starts at `http://127.0.0.1:8080` by default.

### 4. Open the browser prototype

Open `http://127.0.0.1:8080`.

You can now create a real database-backed account, log in, browse products, add items to a cart, edit the profile and run prototype checkout.

## Using an already-mounted PostgreSQL database

If your database already exists, update `.env` with its credentials. Apply `Resources/db/migration/V1__initial_schema.sql` and then `V2__seed_products.sql` using Flyway against that database. Do not run both Fluent schema migrations and Flyway for the same tables; this project intentionally uses Flyway as the only schema migration owner.

## SwiftUI frontend

See `frontend/README.md`. The SwiftUI source is wired to the same REST API and is the **fully Swift frontend**.

## Important PWA / "Swift-only" distinction

SwiftUI does not run directly in a normal browser. A conventional PWA requires browser technologies for its document, styling and service worker. For Phase 1:

- `frontend/` = fully Swift SwiftUI client.
- `backend/Public/` = thin browser/PWA demonstration consuming the Swift Vapor backend.

If the supervisor specifically requires the **browser UI logic itself** to be written in Swift, the next phase should evaluate Swift/Wasm (for example a Swift WebAssembly UI approach) rather than pretending HTML/JavaScript are Swift.

## Main REST endpoints

See `shared/APIContracts/phase1-api.md` for the complete list. The main groups are:

- `/api/v1/auth/*`
- `/api/v1/profile`
- `/api/v1/products`
- `/api/v1/categories`
- `/api/v1/cart/*`
- `/api/v1/orders/*`

## Phase 2 candidates

After Phase 1 is verified, sensible additions are product admin/inventory management, favorites, delivery addresses, real payment integration, product reviews, image upload/storage, stronger production token/session management and deployment configuration.
