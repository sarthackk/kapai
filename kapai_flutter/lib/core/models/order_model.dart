import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_model.dart';

enum OrderStatus { newOrder, accepted, preparing, ready, completed, cancelled }
enum OrderType { dineIn, takeaway }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.newOrder => 'New',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  String get firestoreValue => switch (this) {
        OrderStatus.newOrder => 'new',
        OrderStatus.accepted => 'accepted',
        OrderStatus.preparing => 'preparing',
        OrderStatus.ready => 'ready',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
      };

  static OrderStatus fromString(String s) => switch (s) {
        'accepted' => OrderStatus.accepted,
        'preparing' => OrderStatus.preparing,
        'ready' => OrderStatus.ready,
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.newOrder,
      };
}

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;
  final String? note;

  const CartItem({
    required this.menuItem,
    required this.quantity,
    this.note,
  });

  double get subtotal => menuItem.price * quantity;
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? note;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.note,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        menuItemId: m['menuItemId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] ?? 0).toDouble(),
        quantity: m['quantity'] ?? 1,
        note: m['note'],
      );

  Map<String, dynamic> toMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
        if (note != null) 'note': note,
      };
}

class OrderModel {
  final String id;
  final String? customerId;
  final String? customerName;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final OrderType orderType;
  final int? tableNumber;
  final String? pickupTime;
  final OrderStatus status;
  final int beansEarned;
  final int? beansRedeemed;
  final String? notes;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.orderType,
    this.tableNumber,
    this.pickupTime,
    required this.status,
    this.beansEarned = 0,
    this.beansRedeemed,
    this.notes,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: d['customerId'],
      customerName: d['customerName'],
      items: (d['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      discount: (d['discount'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      orderType: d['orderType'] == 'takeaway' ? OrderType.takeaway : OrderType.dineIn,
      tableNumber: d['tableNumber'],
      pickupTime: d['pickupTime'],
      status: OrderStatusX.fromString(d['status'] ?? 'new'),
      beansEarned: d['beansEarned'] ?? 0,
      beansRedeemed: d['beansRedeemed'],
      notes: d['notes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        if (customerId != null) 'customerId': customerId,
        if (customerName != null) 'customerName': customerName,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'orderType': orderType == OrderType.takeaway ? 'takeaway' : 'dine_in',
        if (tableNumber != null) 'tableNumber': tableNumber,
        if (pickupTime != null) 'pickupTime': pickupTime,
        'status': status.firestoreValue,
        'beansEarned': beansEarned,
        if (beansRedeemed != null) 'beansRedeemed': beansRedeemed,
        if (notes != null) 'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        customerId: customerId,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        discount: discount,
        total: total,
        orderType: orderType,
        tableNumber: tableNumber,
        pickupTime: pickupTime,
        status: status ?? this.status,
        beansEarned: beansEarned,
        beansRedeemed: beansRedeemed,
        notes: notes,
        createdAt: createdAt,
      );
}
