# Features by Module

## Dashboard
KPI cards: Today's Sales, Monthly Sales, Outstanding Debts, Inventory Value,
Products Near Expiry, Gross Profit.
Charts: Monthly Sales Trend, Top Selling Products, Sales by Customer.
Alerts feed: Low Stock, Near Expiry, Overdue Customers.

## Products
Fields: barcode, product name, generic name, brand name, category,
manufacturer, supplier, batch number, cost price, selling price, stock
quantity (derived), reorder level, expiry date, status.
Actions: add, edit, delete, barcode search, text search, bulk import, export.

## Inventory
Actions: stock in, stock out, inventory adjustment, stock transfer.
Batch tracking is mandatory — every stock-in creates or updates a batch row.
Alerts: low stock, out of stock, near expiry, expired.
Current stock is always computed from the stock_movements ledger (see
DATABASE_SCHEMA.md), never edited directly.

## Batch Tracking
Fields: batch number, manufacture date, expiry date, quantity, supplier,
purchase cost.
Hard rule: sales must always draw from the batch with the earliest expiry
date first (FIFO). This logic lives in the sales/invoice-building flow, not
just in inventory.

## Customers
Fields: business name, contact person, phone, email, address, credit limit,
outstanding balance, status.
Actions: search, purchase history, statement generation, credit monitoring,
payment history.

## Sales / Invoicing
Workflow (must complete in under 30 seconds for a typical invoice):
select customer → search product → add product → adjust quantity → apply
discount → generate invoice → receive payment → print/share invoice.

Invoice layout:
- Header: company logo, company name, phone numbers, invoice number, date,
  customer name, cashier name, attendant
- Body: qty, description, unit price, discount, line total
- Footer: subtotal, discount, VAT, grand total, amount paid, balance,
  invoice status, print count, QR code, electronic invoice notice
- Export: PDF, share via WhatsApp, print, download

## Credit Sales
Statuses: paid, partial, unpaid, overdue.
Features: credit invoices, due dates, partial payments, debt tracking.
Reports: customer debt report, aging analysis, payment history.

## Expiry Monitoring
Windows: 30 / 60 / 90 days out.
Features: expiry alerts, expired product report, disposal tracking.

## Reports
- Sales: daily, weekly, monthly, quarterly, annual
- Inventory: current stock, low stock, stock movement, expiry report
- Customers: top customers, debt report, customer purchases
- Profit: daily profit, monthly profit, product profitability

## Notifications (push)
Low stock alert, expiry alert, overdue customer alert, new sale confirmation,
backup reminder.

## Offline Support
Sales must function fully offline; invoices persist in SQLite immediately and
sync automatically on reconnect. See ARCHITECTURE.md "Why offline-first
matters here" for the sync design.

## Security
JWT auth, role-based access control, encrypted passwords, session expiry,
audit logging on all mutating actions.
