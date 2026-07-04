import 'package:cloud_firestore/cloud_firestore.dart';

enum ProcurementStatus { pending, approved, rejected, ordered, received }
enum ProcurementUrgency { low, medium, high }

extension ProcurementStatusX on ProcurementStatus {
  String get label => switch (this) {
        ProcurementStatus.pending => 'Pending',
        ProcurementStatus.approved => 'Approved',
        ProcurementStatus.rejected => 'Rejected',
        ProcurementStatus.ordered => 'Ordered',
        ProcurementStatus.received => 'Received',
      };
}

extension ProcurementUrgencyX on ProcurementUrgency {
  String get label => switch (this) {
        ProcurementUrgency.low => 'Low',
        ProcurementUrgency.medium => 'Medium',
        ProcurementUrgency.high => 'High',
      };
}

class ProcurementRequestModel {
  final String id;
  final String itemId;
  final String itemName;
  final String category;
  final double quantity;
  final String unit;
  final ProcurementUrgency urgency;
  final ProcurementStatus status;
  final String requestedBy;
  final String requestedByName;
  final String? approvedBy;
  final String? approvedByName;
  final String? vendorId;
  final String? vendorName;
  final String? notes;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? orderedAt;
  final DateTime? receivedAt;

  const ProcurementRequestModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.urgency,
    required this.status,
    required this.requestedBy,
    required this.requestedByName,
    this.approvedBy,
    this.approvedByName,
    this.vendorId,
    this.vendorName,
    this.notes,
    required this.createdAt,
    this.approvedAt,
    this.orderedAt,
    this.receivedAt,
  });

  factory ProcurementRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProcurementRequestModel(
      id: doc.id,
      itemId: d['itemId'] ?? '',
      itemName: d['itemName'] ?? '',
      category: d['category'] ?? '',
      quantity: (d['quantity'] ?? 0).toDouble(),
      unit: d['unit'] ?? '',
      urgency: ProcurementUrgency.values.firstWhere(
        (u) => u.name == (d['urgency'] ?? 'medium'),
        orElse: () => ProcurementUrgency.medium,
      ),
      status: ProcurementStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'pending'),
        orElse: () => ProcurementStatus.pending,
      ),
      requestedBy: d['requestedBy'] ?? '',
      requestedByName: d['requestedByName'] ?? '',
      approvedBy: d['approvedBy'],
      approvedByName: d['approvedByName'],
      vendorId: d['vendorId'],
      vendorName: d['vendorName'],
      notes: d['notes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (d['approvedAt'] as Timestamp?)?.toDate(),
      orderedAt: (d['orderedAt'] as Timestamp?)?.toDate(),
      receivedAt: (d['receivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'itemId': itemId,
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'urgency': urgency.name,
        'status': status.name,
        'requestedBy': requestedBy,
        'requestedByName': requestedByName,
        if (approvedBy != null) 'approvedBy': approvedBy,
        if (approvedByName != null) 'approvedByName': approvedByName,
        if (vendorId != null) 'vendorId': vendorId,
        if (vendorName != null) 'vendorName': vendorName,
        if (notes != null) 'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
        if (orderedAt != null) 'orderedAt': Timestamp.fromDate(orderedAt!),
        if (receivedAt != null) 'receivedAt': Timestamp.fromDate(receivedAt!),
      };

  ProcurementRequestModel copyWith({
    ProcurementStatus? status,
    String? approvedBy,
    String? approvedByName,
    String? vendorId,
    String? vendorName,
    DateTime? approvedAt,
    DateTime? orderedAt,
    DateTime? receivedAt,
  }) =>
      ProcurementRequestModel(
        id: id,
        itemId: itemId,
        itemName: itemName,
        category: category,
        quantity: quantity,
        unit: unit,
        urgency: urgency,
        status: status ?? this.status,
        requestedBy: requestedBy,
        requestedByName: requestedByName,
        approvedBy: approvedBy ?? this.approvedBy,
        approvedByName: approvedByName ?? this.approvedByName,
        vendorId: vendorId ?? this.vendorId,
        vendorName: vendorName ?? this.vendorName,
        notes: notes,
        createdAt: createdAt,
        approvedAt: approvedAt ?? this.approvedAt,
        orderedAt: orderedAt ?? this.orderedAt,
        receivedAt: receivedAt ?? this.receivedAt,
      );
}
