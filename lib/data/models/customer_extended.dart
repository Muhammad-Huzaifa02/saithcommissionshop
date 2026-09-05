class CustomerExtended {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String password;
  final DateTime createdAt;
  final bool isActive;
  final double creditLimit;
  final double usedCredit;
  final int loyaltyPoints;
  final String tier;
  final DateTime? lastPurchaseDate;
  final String? notes;
  final List<String> tags;
  final String? city;
  final String? cnic;

  const CustomerExtended({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.password,
    required this.createdAt,
    this.isActive = true,
    this.creditLimit = 0,
    this.usedCredit = 0,
    this.loyaltyPoints = 0,
    this.tier = 'Bronze',
    this.lastPurchaseDate,
    this.notes,
    this.tags = const [],
    this.city,
    this.cnic,
  });

  double get availableCredit => creditLimit - usedCredit;
  bool get hasCredit => availableCredit > 0;

  String get tierEmoji {
    switch (tier) {
      case 'Gold': return '🥇';
      case 'Silver': return '🥈';
      default: return '🥉';
    }
  }

  CustomerExtended copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? password,
    bool? isActive,
    double? creditLimit,
    double? usedCredit,
    int? loyaltyPoints,
    String? tier,
    DateTime? lastPurchaseDate,
    String? notes,
    List<String>? tags,
    String? city,
    String? cnic,
  }) {
    return CustomerExtended(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      password: password ?? this.password,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      creditLimit: creditLimit ?? this.creditLimit,
      usedCredit: usedCredit ?? this.usedCredit,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      tier: tier ?? this.tier,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      city: city ?? this.city,
      cnic: cnic ?? this.cnic,
    );
  }
}
