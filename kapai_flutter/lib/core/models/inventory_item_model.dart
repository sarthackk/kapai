import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kInventoryCategories = [
  'Grocery Items',
  'Vegetables',
  'Dairy Products',
  'Dry Store',
  'Non-Veg',
  'Breads',
  'Beverages',
];

class InventoryItemModel {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minThreshold;
  final double? costPrice;
  final bool isActive;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    this.minThreshold = 0,
    this.costPrice,
    this.isActive = true,
  });

  bool get isLowStock => currentStock <= minThreshold && minThreshold > 0;

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      unit: d['unit'] ?? 'pcs',
      currentStock: (d['currentStock'] ?? 0).toDouble(),
      minThreshold: (d['minThreshold'] ?? 0).toDouble(),
      costPrice: d['costPrice']?.toDouble(),
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'unit': unit,
        'currentStock': currentStock,
        'minThreshold': minThreshold,
        if (costPrice != null) 'costPrice': costPrice,
        'isActive': isActive,
      };

  InventoryItemModel copyWith({
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minThreshold,
    double? costPrice,
    bool? isActive,
  }) =>
      InventoryItemModel(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        currentStock: currentStock ?? this.currentStock,
        minThreshold: minThreshold ?? this.minThreshold,
        costPrice: costPrice ?? this.costPrice,
        isActive: isActive ?? this.isActive,
      );
}
