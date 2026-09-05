class Customer {
  final String id; // This is the Auth UID
  final String customerId; // This is the unique CUST-0001 format
  final String name;
  final String phone;
  final String email;
  final String address;
  final String password;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;

  const Customer({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.password,
    this.imageUrl,
    required this.createdAt,
    this.isActive = true,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? password,
    String? imageUrl,
    bool? isActive,
  }) {
    return Customer(
      id: id,
      customerId: customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      password: password ?? this.password,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
