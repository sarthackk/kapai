import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isVeg;
  final bool isAvailable;
  final bool isBestseller;
  final bool isNew;
  final int beansValue;
  final int sortOrder;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isVeg = true,
    this.isAvailable = true,
    this.isBestseller = false,
    this.isNew = false,
    this.beansValue = 0,
    this.sortOrder = 0,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'],
      price: (d['price'] ?? 0).toDouble(),
      category: d['category'] ?? '',
      imageUrl: d['imageUrl'],
      isVeg: d['isVeg'] ?? true,
      isAvailable: d['isAvailable'] ?? true,
      isBestseller: d['isBestseller'] ?? false,
      isNew: d['isNew'] ?? false,
      beansValue: d['beansValue'] ?? 0,
      sortOrder: d['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (description != null) 'description': description,
        'price': price,
        'category': category,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isVeg': isVeg,
        'isAvailable': isAvailable,
        'isBestseller': isBestseller,
        'isNew': isNew,
        'beansValue': beansValue,
        'sortOrder': sortOrder,
      };

  MenuItemModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isVeg,
    bool? isAvailable,
    bool? isBestseller,
    bool? isNew,
    int? beansValue,
    int? sortOrder,
  }) =>
      MenuItemModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        isVeg: isVeg ?? this.isVeg,
        isAvailable: isAvailable ?? this.isAvailable,
        isBestseller: isBestseller ?? this.isBestseller,
        isNew: isNew ?? this.isNew,
        beansValue: beansValue ?? this.beansValue,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
