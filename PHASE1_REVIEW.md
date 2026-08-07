# Phase 1 review checklist

Use this file when reviewing the returned prototype.

## Backend

- [ ] `swift run Run` starts without compilation errors.
- [ ] `GET /health` returns `ShopSwift API is running`.
- [ ] PostgreSQL credentials in `backend/.env` are correct.
- [ ] Flyway created `flyway_schema_history` and applied V1 + V2.
- [ ] Signup rejects duplicate email/username.
- [ ] Login rejects an account that does not exist.
- [ ] Login rejects a wrong password.
- [ ] Protected routes reject missing/invalid bearer tokens.
- [ ] Password change invalidates the old token.
- [ ] Cart quantities cannot exceed stock.
- [ ] Checkout empties the cart and reduces stock.

## Frontend

- [ ] Browser PWA opens at `/` when the backend is running.
- [ ] Signup/login UI receives real API responses.
- [ ] Products are loaded from PostgreSQL through Vapor.
- [ ] Cart changes persist after refresh.
- [ ] Profile edits persist after refresh.
- [ ] SwiftUI project files are added to an iOS 17+ Xcode target.
- [ ] `AppConfiguration.apiBaseURL` points to the correct backend host.

## Architecture decision

**Phase 1 uses REST only.** Add WebSockets later only for features with a genuine real-time requirement.
