import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String id;
  final String name;
  final String contactName;
  final String phone;
  final String? email;
  final List<String> categories;
  final String? notes;
  final bool isActive;

  const VendorModel({
    required this.id,
    required this.name,
    required this.contactName,
    required this.phone,
    this.email,
    required this.categories,
    this.notes,
    this.isActive = true,
  });

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id: doc.id,
      name: d['name'] ?? '',
      contactName: d['contactName'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'],
      categories: List<String>.from(d['categories'] ?? []),
      notes: d['notes'],
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'contactName': contactName,
        'phone': phone,
        if (email != null) 'email': email,
        'categories': categories,
        if (notes != null) 'notes': notes,
        'isActive': isActive,
      };

  VendorModel copyWith({
    String? name,
    String? contactName,
    String? phone,
    String? email,
    List<String>? categories,
    String? notes,
    bool? isActive,
  }) =>
      VendorModel(
        id: id,
        name: name ?? this.name,
        contactName: contactName ?? this.contactName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        categories: categories ?? this.categories,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
      );
}
