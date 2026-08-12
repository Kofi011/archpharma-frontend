class ProductItem {
  final String id;
  final String barcode;
  final String productName;
  final String genericName;
  final String brandName;
  final String category;
  final String manufacturer;
  final double costPrice;
  final double sellingPrice;
  final int reorderLevel;
  final String status;
  final int currentStock; // Derived from stock_movements ledger

  const ProductItem({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.genericName,
    required this.brandName,
    required this.category,
    required this.manufacturer,
    required this.costPrice,
    required this.sellingPrice,
    required this.reorderLevel,
    required this.status,
    required this.currentStock,
  });

  double get margin => sellingPrice - costPrice;
  bool get isLowStock => currentStock <= reorderLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'productName': productName,
    'genericName': genericName,
    'brandName': brandName,
    'category': category,
    'manufacturer': manufacturer,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'reorderLevel': reorderLevel,
    'status': status,
    'currentStock': currentStock,
  };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
    id: json['id'] as String,
    barcode: json['barcode'] as String? ?? '',
    productName: json['productName'] as String,
    genericName: json['genericName'] as String? ?? '',
    brandName: json['brandName'] as String? ?? '',
    category: json['category'] as String? ?? '',
    manufacturer: json['manufacturer'] as String? ?? '',
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
    reorderLevel: (json['reorderLevel'] as num?)?.toInt() ?? 10,
    status: json['status'] as String? ?? 'active',
    currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
  );
}
