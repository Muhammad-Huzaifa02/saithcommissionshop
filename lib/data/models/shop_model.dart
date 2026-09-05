/// A single shop/tenant on the Mandi Management Platform.
///
/// Every shop-scoped document elsewhere in the app (products, customers,
/// invoices, ...) carries this shop's [id] as its `shopId` field. Nothing
/// here should ever be assumed to be "the" shop the way the old singleton
/// `shop/info` document was — always resolve the current shop through
/// ShopContextProvider, never hardcode an id.
class Shop {
  final String id;
  final String name;
  final String? logoUrl;
  final String ownerUid;
  final List<String> businessTypes;

  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String city;
  final String district;
  final String province;

  final String ntn;  // National Tax Number (optional)
  final String strn; // Sales Tax Registration Number (optional)

  final String defaultWeightUnit;       // e.g. "40kg", "50kg", "kg", "mann"
  final double defaultCommissionPercent;
  final String invoicePrefix;
  final int invoiceNextNumber;
  final String receiptPrefix;
  final int receiptNextNumber;

  final String currency; // "PKR"
  final ShopStatus status;
  final DateTime? createdAt;

  const Shop({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.ownerUid,
    this.businessTypes = const [],
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.province = '',
    this.ntn = '',
    this.strn = '',
    this.defaultWeightUnit = '40kg',
    this.defaultCommissionPercent = 0,
    this.invoicePrefix = 'INV',
    this.invoiceNextNumber = 1,
    this.receiptPrefix = 'RCPT',
    this.receiptNextNumber = 1,
    this.currency = 'PKR',
    this.status = ShopStatus.active,
    this.createdAt,
  });

  factory Shop.fromMap(String id, Map<String, dynamic> d) => Shop(
        id: id,
        name: d['name'] as String? ?? '',
        logoUrl: d['logoUrl'] as String?,
        ownerUid: d['ownerUid'] as String? ?? '',
        businessTypes: (d['businessTypes'] as List?)?.cast<String>() ?? const [],
        phone: d['phone'] as String? ?? '',
        whatsapp: d['whatsapp'] as String? ?? '',
        email: d['email'] as String? ?? '',
        address: d['address'] as String? ?? '',
        city: d['city'] as String? ?? '',
        district: d['district'] as String? ?? '',
        province: d['province'] as String? ?? '',
        ntn: d['ntn'] as String? ?? '',
        strn: d['strn'] as String? ?? '',
        defaultWeightUnit: d['defaultWeightUnit'] as String? ?? '40kg',
        defaultCommissionPercent:
            (d['defaultCommissionPercent'] as num?)?.toDouble() ?? 0,
        invoicePrefix: d['invoicePrefix'] as String? ?? 'INV',
        invoiceNextNumber: (d['invoiceNextNumber'] as num?)?.toInt() ?? 1,
        receiptPrefix: d['receiptPrefix'] as String? ?? 'RCPT',
        receiptNextNumber: (d['receiptNextNumber'] as num?)?.toInt() ?? 1,
        currency: d['currency'] as String? ?? 'PKR',
        status: ShopStatusX.fromString(d['status'] as String?),
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'logoUrl': logoUrl,
        'ownerUid': ownerUid,
        'businessTypes': businessTypes,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'address': address,
        'city': city,
        'district': district,
        'province': province,
        'ntn': ntn,
        'strn': strn,
        'defaultWeightUnit': defaultWeightUnit,
        'defaultCommissionPercent': defaultCommissionPercent,
        'invoicePrefix': invoicePrefix,
        'invoiceNextNumber': invoiceNextNumber,
        'receiptPrefix': receiptPrefix,
        'receiptNextNumber': receiptNextNumber,
        'currency': currency,
        'status': status.name,
      };

  Shop copyWith({
    String? name,
    String? logoUrl,
    List<String>? businessTypes,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? city,
    String? district,
    String? province,
    String? ntn,
    String? strn,
    String? defaultWeightUnit,
    double? defaultCommissionPercent,
    String? invoicePrefix,
    int? invoiceNextNumber,
    String? receiptPrefix,
    int? receiptNextNumber,
    ShopStatus? status,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerUid: ownerUid,
      businessTypes: businessTypes ?? this.businessTypes,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      province: province ?? this.province,
      ntn: ntn ?? this.ntn,
      strn: strn ?? this.strn,
      defaultWeightUnit: defaultWeightUnit ?? this.defaultWeightUnit,
      defaultCommissionPercent:
          defaultCommissionPercent ?? this.defaultCommissionPercent,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceNextNumber: invoiceNextNumber ?? this.invoiceNextNumber,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      receiptNextNumber: receiptNextNumber ?? this.receiptNextNumber,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

enum ShopStatus { active, suspended }

extension ShopStatusX on ShopStatus {
  static ShopStatus fromString(String? s) =>
      ShopStatus.values.firstWhere((e) => e.name == s, orElse: () => ShopStatus.active);
}
