/// Links one Firebase Auth user to one shop, with a role.
///
/// A user can have more than one ShopMember doc (one per shop they belong
/// to) — that's what makes the Shop Switcher possible. Always resolve
/// "what can this user do right now" through ShopContextProvider, which
/// picks the ShopMember matching the currently active shop.
class ShopMember {
  final String id;       // Firestore doc id
  final String shopId;
  final String uid;      // Firebase Auth uid
  final String roleId;
  final String name;
  final String phone;
  final String email;
  final String? cnic;
  final DateTime? joiningDate;
  final double? salary;
  final MemberStatus status;
  final String? photoUrl;
  final DateTime? createdAt;

  const ShopMember({
    required this.id,
    required this.shopId,
    required this.uid,
    required this.roleId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.cnic,
    this.joiningDate,
    this.salary,
    this.status = MemberStatus.active,
    this.photoUrl,
    this.createdAt,
  });

  bool get isActive => status == MemberStatus.active;
  bool get isOwnerRole => roleId == 'owner';

  factory ShopMember.fromMap(String id, Map<String, dynamic> d) => ShopMember(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        uid: d['uid'] as String? ?? '',
        roleId: d['roleId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        email: d['email'] as String? ?? '',
        cnic: d['cnic'] as String?,
        joiningDate: (d['joiningDate'] as dynamic)?.toDate(),
        salary: (d['salary'] as num?)?.toDouble(),
        status: MemberStatusX.fromString(d['status'] as String?),
        photoUrl: d['photoUrl'] as String?,
        createdAt: (d['createdAt'] as dynamic)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'uid': uid,
        'roleId': roleId,
        'name': name,
        'phone': phone,
        'email': email,
        'cnic': cnic,
        'joiningDate': joiningDate,
        'salary': salary,
        'status': status.name,
        'photoUrl': photoUrl,
      };

  ShopMember copyWith({
    String? roleId,
    String? name,
    String? phone,
    String? email,
    String? cnic,
    DateTime? joiningDate,
    double? salary,
    MemberStatus? status,
    String? photoUrl,
  }) {
    return ShopMember(
      id: id,
      shopId: shopId,
      uid: uid,
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      joiningDate: joiningDate ?? this.joiningDate,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}

enum MemberStatus { active, inactive }

extension MemberStatusX on MemberStatus {
  static MemberStatus fromString(String? s) => MemberStatus.values
      .firstWhere((e) => e.name == s, orElse: () => MemberStatus.active);
}
