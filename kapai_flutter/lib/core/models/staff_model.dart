import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole { superAdmin, admin, staff }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
        StaffRole.superAdmin => 'Super Admin',
        StaffRole.admin => 'Admin',
        StaffRole.staff => 'Staff',
      };

  String get firestoreValue => switch (this) {
        StaffRole.superAdmin => 'super_admin',
        StaffRole.admin => 'admin',
        StaffRole.staff => 'staff',
      };

  static StaffRole fromString(String s) => switch (s) {
        'super_admin' => StaffRole.superAdmin,
        'admin' => StaffRole.admin,
        _ => StaffRole.staff,
      };
}

class StaffPermissions {
  final bool canManageOrders;
  final bool canManageTakeaway;
  final bool canManageInventory;
  final bool canViewReports;
  final bool canManageMenu;
  final bool canManageStaff;
  final bool canManageVendors;
  final bool canApproveProcurement;

  const StaffPermissions({
    this.canManageOrders = false,
    this.canManageTakeaway = false,
    this.canManageInventory = false,
    this.canViewReports = false,
    this.canManageMenu = false,
    this.canManageStaff = false,
    this.canManageVendors = false,
    this.canApproveProcurement = false,
  });

  static const StaffPermissions none = StaffPermissions();

  static const StaffPermissions staffDefault = StaffPermissions(
    canManageOrders: true,
    canManageTakeaway: true,
  );

  factory StaffPermissions.fromMap(Map<String, dynamic> m) => StaffPermissions(
        canManageOrders: m['canManageOrders'] ?? false,
        canManageTakeaway: m['canManageTakeaway'] ?? false,
        canManageInventory: m['canManageInventory'] ?? false,
        canViewReports: m['canViewReports'] ?? false,
        canManageMenu: m['canManageMenu'] ?? false,
        canManageStaff: m['canManageStaff'] ?? false,
        canManageVendors: m['canManageVendors'] ?? false,
        canApproveProcurement: m['canApproveProcurement'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'canManageOrders': canManageOrders,
        'canManageTakeaway': canManageTakeaway,
        'canManageInventory': canManageInventory,
        'canViewReports': canViewReports,
        'canManageMenu': canManageMenu,
        'canManageStaff': canManageStaff,
        'canManageVendors': canManageVendors,
        'canApproveProcurement': canApproveProcurement,
      };

  StaffPermissions copyWith({
    bool? canManageOrders,
    bool? canManageTakeaway,
    bool? canManageInventory,
    bool? canViewReports,
    bool? canManageMenu,
    bool? canManageStaff,
    bool? canManageVendors,
    bool? canApproveProcurement,
  }) =>
      StaffPermissions(
        canManageOrders: canManageOrders ?? this.canManageOrders,
        canManageTakeaway: canManageTakeaway ?? this.canManageTakeaway,
        canManageInventory: canManageInventory ?? this.canManageInventory,
        canViewReports: canViewReports ?? this.canViewReports,
        canManageMenu: canManageMenu ?? this.canManageMenu,
        canManageStaff: canManageStaff ?? this.canManageStaff,
        canManageVendors: canManageVendors ?? this.canManageVendors,
        canApproveProcurement: canApproveProcurement ?? this.canApproveProcurement,
      );
}

class StaffModel {
  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final List<String> assignedCategories;
  final StaffPermissions permissions;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedCategories = const [],
    required this.permissions,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == StaffRole.superAdmin;
  bool get isAdmin => role == StaffRole.admin;

  bool can(String permission) {
    if (isSuperAdmin) return true;
    return switch (permission) {
      'manageOrders' => permissions.canManageOrders,
      'manageTakeaway' => permissions.canManageTakeaway,
      'manageInventory' => permissions.canManageInventory,
      'viewReports' => permissions.canViewReports,
      'manageMenu' => permissions.canManageMenu,
      'manageStaff' => permissions.canManageStaff,
      'manageVendors' => permissions.canManageVendors,
      'approveProcurement' => permissions.canApproveProcurement,
      _ => false,
    };
  }

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StaffModel(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: StaffRoleX.fromString(d['role'] ?? 'staff'),
      assignedCategories: List<String>.from(d['assignedCategories'] ?? []),
      permissions: StaffPermissions.fromMap(
        Map<String, dynamic>.from(d['permissions'] ?? {}),
      ),
      isActive: d['isActive'] ?? true,
      createdBy: d['createdBy'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role.firestoreValue,
        'assignedCategories': assignedCategories,
        'permissions': permissions.toMap(),
        'isActive': isActive,
        if (createdBy != null) 'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  StaffModel copyWith({
    String? name,
    String? email,
    StaffRole? role,
    List<String>? assignedCategories,
    StaffPermissions? permissions,
    bool? isActive,
  }) =>
      StaffModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        assignedCategories: assignedCategories ?? this.assignedCategories,
        permissions: permissions ?? this.permissions,
        isActive: isActive ?? this.isActive,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}
