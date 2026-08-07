# ShopSwift Phase 1 REST API

Base URL (local): `http://127.0.0.1:8080`

## Why REST instead of WebSockets?

Shopping Phase 1 is mostly request/response CRUD: create account, login, read products, update profile, mutate cart, and checkout. REST keeps those actions simple, debuggable, and easy for both SwiftUI and a PWA to consume. WebSockets become useful later for live order tracking, inventory updates, chat, or real-time notifications.

## Public endpoints

- `GET /health`
- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `GET /api/v1/products`
- `GET /api/v1/products?category=Phones`
- `GET /api/v1/products/:productID`
- `GET /api/v1/categories`

## Authenticated endpoints

Send `Authorization: Bearer <token>`.

- `POST /api/v1/auth/logout`
- `GET /api/v1/profile`
- `PATCH /api/v1/profile`
- `PATCH /api/v1/profile/password`
- `GET /api/v1/cart`
- `POST /api/v1/cart/items`
- `PATCH /api/v1/cart/items/:cartItemID`
- `DELETE /api/v1/cart/items/:cartItemID`
- `DELETE /api/v1/cart`
- `GET /api/v1/orders`
- `POST /api/v1/orders/checkout`

## Example signup

```json
{
  "username": "noah",
  "email": "noah@example.com",
  "password": "password123"
}
```

## Example add-to-cart

```json
{
  "productID": "10000000-0000-0000-0000-000000000001",
  "quantity": 1
}
```
