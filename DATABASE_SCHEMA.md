# Database Schema (reference)

This is a field-level reference distilled from the PRD, not final DDL. Use it
to scaffold the initial migrations, then adjust types/constraints as needed.
Every table needs `id` (UUID, client-generatable), `created_at`, `updated_at`,
and — for anything created on-device — `sync_status`.

## users
- id, name, email, phone, password_hash, role (admin | cashier | storekeeper | accountant), status, last_login_at

## products
- id, barcode, product_name, generic_name, brand_name, category, manufacturer,
  supplier_id, cost_price, selling_price, reorder_level, status

Note: stock quantity and expiry live on **batches**, not on the product row —
a product can have multiple batches with different expiry dates.

## batches
- id, product_id (FK), batch_number, manufacture_date, expiry_date, quantity,
  supplier_id (FK), purchase_cost
- Rule: sales must consume the batch with the earliest expiry_date first (FIFO).

## stock_movements (append-only ledger — do not mutate past rows)
- id, product_id (FK), batch_id (FK), type (stock_in | stock_out | adjustment | transfer),
  quantity, reference_type (purchase | sale | adjustment | transfer), reference_id,
  performed_by (FK users), created_at

Current stock for a product = opening stock + sum(stock_in) − sum(stock_out) ±
adjustments, computed from this ledger, not stored as a mutable counter — this
is what makes multi-device offline sync safe.

## customers
- id, business_name, contact_person, phone, email, address, credit_limit,
  outstanding_balance, status

## invoices
- id, invoice_number, customer_id (FK, nullable for walk-in), cashier_id (FK),
  attendant, invoice_date, subtotal, discount, vat, grand_total, amount_paid,
  balance, status (paid | partial | unpaid | overdue), print_count, qr_code

## invoice_items
- id, invoice_id (FK), product_id (FK), batch_id (FK), qty, unit_price,
  discount, line_total

## payments
- id, invoice_id (FK), customer_id (FK), amount, method, paid_at, recorded_by (FK users)

## credit_terms (extends invoices where status is credit)
- invoice_id (FK), due_date, aging_bucket (computed: current | 30 | 60 | 90+)

## suppliers
- id, name, contact_person, phone, email, address

## notifications
- id, user_id (FK), type (low_stock | expiry | overdue_customer | new_sale | backup_reminder),
  payload, read_at, created_at

## audit_log
- id, user_id (FK), action, entity_type, entity_id, before, after, created_at

## Key derived values (compute, don't store redundantly where avoidable)

- **Per-product profit** = selling_price − cost_price
- **Per-invoice profit** = sum(invoice_items line profit)
- **Monthly sales** = sum of completed invoice `grand_total` within the month
- **Monthly profit** = sum of invoice profits within the month
- **Current stock** = derived from `stock_movements`, see above
- **Aging bucket** = derived from `due_date` vs today, see credit_terms
