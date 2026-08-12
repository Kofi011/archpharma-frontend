import 'package:drift/drift.dart';

part 'app_database.g.dart';

enum SyncStatus { pending, synced, conflict }

class Products extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get barcode => text().nullable()();
  TextColumn get productName => text()();
  TextColumn get genericName => text().nullable()();
  TextColumn get brandName => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  IntColumn get reorderLevel => integer().withDefault(const Constant(10))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Batches extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchNumber => text()();
  DateTimeColumn get manufactureDate => dateTime().nullable()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get supplierId => text().nullable()();
  RealColumn get purchaseCost => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class StockMovements extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchId => text().nullable().references(Batches, #id)();
  TextColumn get type => text()(); // stock_in, stock_out, adjustment, transfer
  IntColumn get quantity => integer()();
  TextColumn get referenceType => text()(); // purchase, sale, adjustment, transfer
  TextColumn get referenceId => text().nullable()();
  TextColumn get performedBy => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get businessName => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  RealColumn get outstandingBalance => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get invoiceNumber => text()();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get cashierId => text()();
  TextColumn get attendant => text().nullable()();
  DateTimeColumn get invoiceDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get vat => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))(); // paid, partial, unpaid, overdue
  IntColumn get printCount => integer().withDefault(const Constant(0))();
  TextColumn get qrCode => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class InvoiceItems extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchId => text().nullable().references(Batches, #id)();
  IntColumn get qty => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get invoiceId => text().references(Invoices, #id)();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get recordedBy => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Products,
  Batches,
  StockMovements,
  Customers,
  Invoices,
  InvoiceItems,
  Payments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
