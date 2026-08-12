class InvoiceItemLine {
  final String id;
  final String productId;
  final String description;
  final String? batchNumber;
  final String? expiryDate;
  final int qty;
  final double unitPrice;
  final double? discount;
  final double lineTotal;

  const InvoiceItemLine({
    required this.id,
    required this.productId,
    required this.description,
    this.batchNumber,
    this.expiryDate,
    required this.qty,
    required this.unitPrice,
    this.discount,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'description': description,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'qty': qty,
    'unitPrice': unitPrice,
    'discount': discount,
    'lineTotal': lineTotal,
  };

  factory InvoiceItemLine.fromJson(Map<String, dynamic> json) => InvoiceItemLine(
    id: json['id'] as String,
    productId: json['productId'] as String,
    description: json['description'] as String,
    batchNumber: json['batchNumber'] as String?,
    expiryDate: json['expiryDate'] as String?,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble(),
    lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
  );
}

class InvoiceRecord {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String cashierName;
  final String attendantName;
  final DateTime invoiceDate;
  final double subtotal;
  final double discount;
  final double vat;
  final double grandTotal;
  final double amountPaid;
  final double balance;
  final String status; // paid, partial, unpaid, overdue
  final int printCount;
  final List<InvoiceItemLine> items;
  final String syncStatus;

  const InvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.cashierName,
    required this.attendantName,
    required this.invoiceDate,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.grandTotal,
    required this.amountPaid,
    required this.balance,
    required this.status,
    required this.printCount,
    required this.items,
    required this.syncStatus,
  });

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isUnpaid => status == 'unpaid';

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'customerId': customerId,
    'customerName': customerName,
    'cashierName': cashierName,
    'attendantName': attendantName,
    'invoiceDate': invoiceDate.toIso8601String(),
    'subtotal': subtotal,
    'discount': discount,
    'vat': vat,
    'grandTotal': grandTotal,
    'amountPaid': amountPaid,
    'balance': balance,
    'status': status,
    'printCount': printCount,
    'items': items.map((i) => i.toJson()).toList(),
    'syncStatus': syncStatus,
  };

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) => InvoiceRecord(
    id: json['id'] as String,
    invoiceNumber: json['invoiceNumber'] as String,
    customerId: json['customerId'] as String? ?? '',
    customerName: json['customerName'] as String? ?? '',
    cashierName: json['cashierName'] as String? ?? '',
    attendantName: json['attendantName'] as String? ?? '',
    invoiceDate: json['invoiceDate'] != null
        ? DateTime.tryParse(json['invoiceDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    vat: (json['vat'] as num?)?.toDouble() ?? 0.0,
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'unpaid',
    printCount: (json['printCount'] as num?)?.toInt() ?? 0,
    items: (json['items'] as List<dynamic>?)
            ?.map((i) => InvoiceItemLine.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [],
    syncStatus: json['syncStatus'] as String? ?? 'synced',
  );
}
