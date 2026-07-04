import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckType { morning, eod }

extension CheckTypeX on CheckType {
  String get label => this == CheckType.morning ? 'Morning' : 'EOD';
  String get firestoreValue => name;
}

class InventoryCheckModel {
  final String id;
  final String itemId;
  final String itemName;
  final String category;
  final CheckType checkType;
  final double quantity;
  final double? adjustment;
  final String? note;
  final String checkedBy;
  final String checkedByName;
  final DateTime timestamp;
  final String date; // 'YYYY-MM-DD'

  const InventoryCheckModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.checkType,
    required this.quantity,
    this.adjustment,
    this.note,
    required this.checkedBy,
    required this.checkedByName,
    required this.timestamp,
    required this.date,
  });

  factory InventoryCheckModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InventoryCheckModel(
      id: doc.id,
      itemId: d['itemId'] ?? '',
      itemName: d['itemName'] ?? '',
      category: d['category'] ?? '',
      checkType: d['checkType'] == 'morning' ? CheckType.morning : CheckType.eod,
      quantity: (d['quantity'] ?? 0).toDouble(),
      adjustment: d['adjustment']?.toDouble(),
      note: d['note'],
      checkedBy: d['checkedBy'] ?? '',
      checkedByName: d['checkedByName'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: d['date'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'itemId': itemId,
        'itemName': itemName,
        'category': category,
        'checkType': checkType.firestoreValue,
        'quantity': quantity,
        if (adjustment != null) 'adjustment': adjustment,
        if (note != null) 'note': note,
        'checkedBy': checkedBy,
        'checkedByName': checkedByName,
        'timestamp': Timestamp.fromDate(timestamp),
        'date': date,
      };
}
