class CustomerItem {
  final String id;
  final String businessName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final double creditLimit;
  final double outstandingBalance;
  final String status;

  const CustomerItem({
    required this.id,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.creditLimit,
    required this.outstandingBalance,
    required this.status,
  });

  double get availableCredit => creditLimit - outstandingBalance;
  double get creditUtilization => creditLimit > 0 ? (outstandingBalance / creditLimit) : 0.0;
  bool get isCreditOverLimit => outstandingBalance > creditLimit;
  bool get hasOutstandingDebt => outstandingBalance > 0;

  CustomerItem copyWith({
    String? id,
    String? businessName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? outstandingBalance,
    String? status,
  }) {
    return CustomerItem(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'creditLimit': creditLimit,
    'outstandingBalance': outstandingBalance,
    'status': status,
  };

  factory CustomerItem.fromJson(Map<String, dynamic> json) => CustomerItem(
    id: json['id'] as String,
    businessName: json['businessName'] as String,
    contactPerson: json['contactPerson'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    address: json['address'] as String? ?? '',
    creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
    outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'active',
  );
}
