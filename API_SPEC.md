# API Reference (draft)

Base: `/api/v1`. All routes except `/auth/login` require a valid JWT. Enforce
role checks server-side per the table in README.md.

## Auth
- `POST /auth/login` → access + refresh token
- `POST /auth/refresh`
- `POST /auth/logout`

## Products
- `GET /products` (search, filter by category/status, barcode lookup)
- `POST /products`
- `GET /products/{id}`
- `PUT /products/{id}`
- `DELETE /products/{id}`
- `POST /products/bulk-import`
- `GET /products/export`

## Inventory / Batches
- `GET /inventory/stock` (current stock per product, derived)
- `POST /inventory/stock-in`
- `POST /inventory/stock-out`
- `POST /inventory/adjustment`
- `POST /inventory/transfer`
- `GET /batches?product_id=`
- `GET /inventory/alerts` (low stock, near expiry, expired)

## Customers
- `GET /customers`
- `POST /customers`
- `GET /customers/{id}`
- `PUT /customers/{id}`
- `GET /customers/{id}/statement`
- `GET /customers/{id}/history`

## Sales / Invoices
- `POST /invoices` (create — must resolve batches via FIFO server-side too,
  as a source of truth check against the client's offline-computed picks)
- `GET /invoices/{id}`
- `GET /invoices` (filter by date, customer, status)
- `POST /invoices/{id}/payments`
- `GET /invoices/{id}/pdf`
- `POST /invoices/{id}/void` (audited)

## Credit
- `GET /credit/aging`
- `GET /credit/overdue`

## Reports
- `GET /reports/sales?period=daily|weekly|monthly|quarterly|annual`
- `GET /reports/inventory/current-stock`
- `GET /reports/inventory/movement`
- `GET /reports/inventory/expiry`
- `GET /reports/customers/top`
- `GET /reports/customers/debt`
- `GET /reports/profit?period=`

## Notifications
- `GET /notifications`
- `POST /notifications/{id}/read`

## Sync (offline clients)
- `POST /sync/push` (batch of pending local records: invoices, payments,
  stock movements — each carrying its client-generated UUID)
- `GET /sync/pull?since=` (server-side changes since last sync timestamp)

## Conventions
- Pagination: `?page=&page_size=` on all list endpoints
- All money fields: integer minor units (e.g. pesewas) or fixed-point decimal
  — pick one convention and apply it everywhere to avoid rounding bugs
- All timestamps: UTC ISO 8601
