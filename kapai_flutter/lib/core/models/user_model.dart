import 'package:cloud_firestore/cloud_firestore.dart';

enum LoyaltyTier { sprout, brew, roast }

extension LoyaltyTierX on LoyaltyTier {
  String get label => switch (this) {
        LoyaltyTier.sprout => 'Sprout',
        LoyaltyTier.brew => 'Brew',
        LoyaltyTier.roast => 'Roast',
      };

  int get minBeans => switch (this) {
        LoyaltyTier.sprout => 0,
        LoyaltyTier.brew => 200,
        LoyaltyTier.roast => 500,
      };
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? birthday; // 'MM-DD'
  final int beans;
  final LoyaltyTier tier;
  final double totalSpent;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.birthday,
    required this.beans,
    required this.tier,
    required this.totalSpent,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'],
      birthday: d['birthday'],
      beans: d['beans'] ?? 0,
      tier: LoyaltyTier.values.firstWhere(
        (t) => t.name == (d['tier'] ?? 'sprout'),
        orElse: () => LoyaltyTier.sprout,
      ),
      totalSpent: (d['totalSpent'] ?? 0).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (birthday != null) 'birthday': birthday,
        'beans': beans,
        'tier': tier.name,
        'totalSpent': totalSpent,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? birthday,
    int? beans,
    LoyaltyTier? tier,
    double? totalSpent,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        birthday: birthday ?? this.birthday,
        beans: beans ?? this.beans,
        tier: tier ?? this.tier,
        totalSpent: totalSpent ?? this.totalSpent,
        createdAt: createdAt,
      );
}
