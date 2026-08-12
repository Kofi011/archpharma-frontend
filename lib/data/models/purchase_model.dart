class PurchaseItem {
  final String orderNo;
  final String supplierName;
  final String dateStr;
  final String productName;
  final double cost;
  final int qty;
  final String status;
  final String batchNo;

  const PurchaseItem({
    required this.orderNo,
    required this.supplierName,
    required this.dateStr,
    required this.productName,
    required this.cost,
    required this.qty,
    required this.status,
    required this.batchNo,
  });

  Map<String, dynamic> toJson() => {
    'orderNo': orderNo,
    'supplierName': supplierName,
    'dateStr': dateStr,
    'productName': productName,
    'cost': cost,
    'qty': qty,
    'status': status,
    'batchNo': batchNo,
  };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    orderNo: json['orderNo'] as String,
    supplierName: json['supplierName'] as String,
    dateStr: json['dateStr'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'Completed',
    batchNo: json['batchNo'] as String? ?? '',
  );
}
