# Development Plan

Build in this order. Each phase should be functional (not just scaffolded)
before moving to the next, because later phases read data structures the
earlier ones create.

## Phase 0 — Foundations
- Repo scaffolding (Flutter app + backend service)
- PostgreSQL schema + migrations from DATABASE_SCHEMA.md
- Auth: JWT login, role-based route guards, session expiry
- Drift (SQLite) local schema mirroring the sync-relevant server tables
- Basic navigation shell: bottom nav (Dashboard, Sales, Inventory, Customers,
  Reports) + FAB for New Invoice

## Phase 1 — Products & Inventory
- Product CRUD, barcode + text search
- Batch tracking, stock-in flow
- Stock movement ledger (append-only) and derived current-stock calculation
- Low stock / near expiry / expired alerts

## Phase 2 — Customers
- Customer CRUD
- Credit limit and outstanding balance fields
- Purchase history view (empty until Phase 3 produces invoices)

## Phase 3 — Sales & Invoicing (core MVP feature)
- Invoice builder: select customer → search product → add → adjust qty →
  discount → generate
- FIFO batch consumption logic (client-side for offline, server-side as the
  source of truth on sync)
- Payment capture, invoice statuses (paid/partial/unpaid/overdue)
- PDF generation, WhatsApp share, print
- Target: full flow completes in under 30 seconds

## Phase 4 — Offline Support & Sync
- SQLite-first writes for invoices, payments, stock movements
- Background sync worker: push pending records, pull server changes
- Conflict handling per the ledger-based approach in ARCHITECTURE.md

## Phase 5 — Credit Sales & Aging
- Due dates, partial payments, aging buckets (30/60/90)
- Customer statements

## Phase 6 — Dashboard & Reports
- KPI cards (depend on Phases 1–5 data being real)
- Charts: monthly sales trend, top products, sales by customer
- Full report set: sales, inventory, customer, profit reports

## Phase 7 — Notifications
- Push notifications for low stock, expiry, overdue customers, new sale,
  backup reminders

## Phase 8 — Polish & Security Hardening
- Audit logging review across all mutating endpoints
- Encrypted password storage confirmed, session expiry tested
- Bulk import/export for products
- QA pass against Success Criteria in README.md

## Definition of done for MVP
All items in the PRD's "MVP Deliverables" checklist are implemented and the
six Success Criteria in README.md are demonstrably true on a real device with
airplane mode toggled mid-session.
