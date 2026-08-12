class SupplierItem {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String status;

  const SupplierItem({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'status': status,
  };

  factory SupplierItem.fromJson(Map<String, dynamic> json) => SupplierItem(
    id: json['id'] as String,
    name: json['name'] as String,
    contactPerson: json['contactPerson'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    address: json['address'] as String? ?? '',
    status: json['status'] as String? ?? 'Active',
  );
}
