class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? ntn;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.ntn,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'address': address,
    'ntn': ntn,
    'createdAt': createdAt,
  };
}
