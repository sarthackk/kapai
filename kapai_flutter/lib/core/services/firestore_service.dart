import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_check_model.dart';
import '../models/procurement_request_model.dart';
import '../models/vendor_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ─────────────────────────────────────────────────────────────

  CollectionReference get _staff => _db.collection('staff');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _menu => _db.collection('menu');
  CollectionReference get _orders => _db.collection('orders');
  CollectionReference get _inventory => _db.collection('inventory');
  CollectionReference get _inventoryLogs => _db.collection('inventory_logs');
  CollectionReference get _procurement => _db.collection('procurement_requests');
  CollectionReference get _vendors => _db.collection('vendors');

  // ── Staff ────────────────────────────────────────────────────────────────────

  Stream<List<StaffModel>> watchAllStaff() => _staff
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(StaffModel.fromFirestore).toList());

  Future<void> updateStaff(StaffModel staff) =>
      _staff.doc(staff.id).update(staff.toFirestore());

  Future<void> deactivateStaff(String id) =>
      _staff.doc(id).update({'isActive': false});

  // ── Inventory ────────────────────────────────────────────────────────────────

  Stream<List<InventoryItemModel>> watchInventory({String? category}) {
    Query q = _inventory.where('isActive', isEqualTo: true).orderBy('name');
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.snapshots().map((s) => s.docs.map(InventoryItemModel.fromFirestore).toList());
  }

  Stream<List<InventoryItemModel>> watchLowStockItems() => _inventory
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map(InventoryItemModel.fromFirestore)
          .where((i) => i.isLowStock)
          .toList());

  Future<void> addInventoryItem(InventoryItemModel item) {
    if (item.id.isEmpty) {
      return _inventory.add(item.toFirestore());
    }
    return _inventory.doc(item.id).set(item.toFirestore());
  }

  Future<void> updateInventoryItem(InventoryItemModel item) =>
      _inventory.doc(item.id).update(item.toFirestore());

  Future<void> updateStockQuantity(
    String itemId,
    double newQuantity,
    double adjustment,
    String checkedBy,
    String checkedByName,
    CheckType checkType, {
    String? note,
    required String category,
    required String itemName,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Update item stock
    batch.update(_inventory.doc(itemId), {'currentStock': newQuantity});

    // Log the check
    final logRef = _inventoryLogs.doc();
    final log = InventoryCheckModel(
      id: logRef.id,
      itemId: itemId,
      itemName: itemName,
      category: category,
      checkType: checkType,
      quantity: newQuantity,
      adjustment: adjustment,
      note: note,
      checkedBy: checkedBy,
      checkedByName: checkedByName,
      timestamp: now,
      date: dateStr,
    );
    batch.set(logRef, log.toFirestore());

    await batch.commit();
  }

  Stream<List<InventoryCheckModel>> watchInventoryLogs({
    String? itemId,
    String? date,
    int limit = 50,
  }) {
    Query q = _inventoryLogs.orderBy('timestamp', descending: true);
    if (itemId != null) q = q.where('itemId', isEqualTo: itemId);
    if (date != null) q = q.where('date', isEqualTo: date);
    return q.limit(limit).snapshots().map(
        (s) => s.docs.map(InventoryCheckModel.fromFirestore).toList());
  }

  // ── Procurement ──────────────────────────────────────────────────────────────

  Stream<List<ProcurementRequestModel>> watchProcurementRequests({
    ProcurementStatus? status,
    String? requestedBy,
  }) {
    Query q = _procurement.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    if (requestedBy != null) q = q.where('requestedBy', isEqualTo: requestedBy);
    return q
        .snapshots()
        .map((s) => s.docs.map(ProcurementRequestModel.fromFirestore).toList());
  }

  Future<void> createProcurementRequest(ProcurementRequestModel req) {
    final ref = _procurement.doc();
    return ref.set(ProcurementRequestModel(
      id: ref.id,
      itemId: req.itemId,
      itemName: req.itemName,
      category: req.category,
      quantity: req.quantity,
      unit: req.unit,
      urgency: req.urgency,
      status: ProcurementStatus.pending,
      requestedBy: req.requestedBy,
      requestedByName: req.requestedByName,
      vendorId: req.vendorId,
      vendorName: req.vendorName,
      notes: req.notes,
      createdAt: DateTime.now(),
    ).toFirestore());
  }

  Future<void> approveProcurementRequest(
    String reqId,
    String approvedBy,
    String approvedByName,
  ) =>
      _procurement.doc(reqId).update({
        'status': ProcurementStatus.approved.name,
        'approvedBy': approvedBy,
        'approvedByName': approvedByName,
        'approvedAt': Timestamp.now(),
      });

  Future<void> rejectProcurementRequest(String reqId) =>
      _procurement.doc(reqId).update({'status': ProcurementStatus.rejected.name});

  Future<void> markProcurementOrdered(String reqId) =>
      _procurement.doc(reqId).update({
        'status': ProcurementStatus.ordered.name,
        'orderedAt': Timestamp.now(),
      });

  Future<void> markProcurementReceived(String reqId) =>
      _procurement.doc(reqId).update({
        'status': ProcurementStatus.received.name,
        'receivedAt': Timestamp.now(),
      });

  // ── Vendors ──────────────────────────────────────────────────────────────────

  Stream<List<VendorModel>> watchVendors() => _vendors
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(VendorModel.fromFirestore).toList());

  Future<void> saveVendor(VendorModel vendor) {
    if (vendor.id.isEmpty) {
      return _vendors.add(vendor.toFirestore());
    }
    return _vendors.doc(vendor.id).set(vendor.toFirestore());
  }

  // ── Menu ─────────────────────────────────────────────────────────────────────

  Stream<List<MenuItemModel>> watchMenu({bool availableOnly = false}) {
    Query q = _menu.orderBy('category').orderBy('sortOrder');
    if (availableOnly) q = q.where('isAvailable', isEqualTo: true);
    return q.snapshots().map((s) => s.docs.map(MenuItemModel.fromFirestore).toList());
  }

  Future<void> saveMenuItem(MenuItemModel item) {
    if (item.id.isEmpty) {
      return _menu.add(item.toFirestore());
    }
    return _menu.doc(item.id).set(item.toFirestore());
  }

  Future<void> toggleMenuItemAvailability(String id, bool available) =>
      _menu.doc(id).update({'isAvailable': available});

  // ── Orders ───────────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchOrders({
    OrderStatus? status,
    OrderType? type,
    String? customerId,
    int limit = 50,
  }) {
    Query q = _orders.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.firestoreValue);
    if (type != null) {
      q = q.where('orderType', isEqualTo: type == OrderType.takeaway ? 'takeaway' : 'dine_in');
    }
    if (customerId != null) q = q.where('customerId', isEqualTo: customerId);
    return q.limit(limit).snapshots().map(
        (s) => s.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<String> createOrder(OrderModel order) async {
    final ref = _orders.doc();
    await ref.set(OrderModel(
      id: ref.id,
      customerId: order.customerId,
      customerName: order.customerName,
      items: order.items,
      subtotal: order.subtotal,
      discount: order.discount,
      total: order.total,
      orderType: order.orderType,
      tableNumber: order.tableNumber,
      pickupTime: order.pickupTime,
      status: OrderStatus.newOrder,
      beansEarned: order.beansEarned,
      beansRedeemed: order.beansRedeemed,
      notes: order.notes,
      createdAt: DateTime.now(),
    ).toFirestore());
    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _orders.doc(orderId).update({'status': status.firestoreValue});

  // ── Users (customers) ────────────────────────────────────────────────────────

  Future<void> updateUser(UserModel user) =>
      _users.doc(user.id).update(user.toFirestore());

  Stream<UserModel?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);

  Stream<List<UserModel>> watchAllUsers({int limit = 100}) => _users
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
}
