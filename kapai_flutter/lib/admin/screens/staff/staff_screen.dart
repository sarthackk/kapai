import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/inventory_item_model.dart';

final _staffListProvider = StreamProvider<List<StaffModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchAllStaff(),
);

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStaff = ref.watch(staffProfileProvider).valueOrNull;
    final staffAsync = ref.watch(_staffListProvider);

    if (!(currentStaff?.isSuperAdmin ?? false)) {
      return const Scaffold(
        body: Center(child: Text('Access restricted to Super Admin')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
            child: Row(
              children: [
                Expanded(child: Text('Staff & Roles', style: AppTextStyles.displaySmall)),
                FilledButton.icon(
                  onPressed: () => _showAddStaffSheet(context, ref),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Add Staff'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                ),
              ],
            ),
          ),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (staffList) {
                if (staffList.isEmpty) {
                  return Center(child: Text('No staff yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _StaffCard(staff: staffList[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddStaffSheet(),
    );
  }
}

class _StaffCard extends ConsumerWidget {
  final StaffModel staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: staff.isSuperAdmin ? AppColors.oliveLight : AppColors.sageLight,
                child: Text(
                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: staff.isSuperAdmin ? AppColors.olive : AppColors.sage,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.name, style: AppTextStyles.labelLarge),
                    Text(staff.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RoleBadge(role: staff.role),
                        if (!staff.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Inactive', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                          ),
                        ],
                      ],
                    ),
                    if (staff.isAdmin && staff.assignedCategories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Categories: ${staff.assignedCategories.join(', ')}',
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStaffSheet(staff: staff),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final StaffRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      StaffRole.superAdmin => (AppColors.oliveLight, AppColors.olive),
      StaffRole.admin      => (AppColors.mossLight, AppColors.moss),
      StaffRole.staff      => (AppColors.sageLight, AppColors.sage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(role.label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
    );
  }
}

class _AddStaffSheet extends ConsumerStatefulWidget {
  const _AddStaffSheet();

  @override
  ConsumerState<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<_AddStaffSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  StaffRole _role = StaffRole.staff;
  final Set<String> _selectedCategories = {};
  StaffPermissions _permissions = StaffPermissions.staffDefault;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.length < 6) return;
    setState(() => _loading = true);

    final currentStaff = ref.read(staffProfileProvider).valueOrNull;

    await ref.read(authServiceProvider).createStaffAccount(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      role: _role,
      assignedCategories: _selectedCategories.toList(),
      permissions: _role == StaffRole.staff ? _permissions : StaffPermissions.none,
      createdBy: currentStaff?.id ?? '',
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Staff Member', style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password (min 6 chars)')),
                  const SizedBox(height: 16),

                  // Role
                  Text('Role', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [StaffRole.admin, StaffRole.staff].map((r) {
                      final selected = _role == r;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: r == StaffRole.admin ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _role = r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.oliveLight : AppColors.cream,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selected ? AppColors.olive : AppColors.creamDark),
                              ),
                              child: Center(
                                child: Text(r.label, style: AppTextStyles.labelLarge.copyWith(color: selected ? AppColors.olive : AppColors.textMid)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Admin: category assignment
                  if (_role == StaffRole.admin) ...[
                    const SizedBox(height: 16),
                    Text('Assign Categories', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kInventoryCategories.map((cat) {
                        final sel = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: sel,
                          onSelected: (v) => setState(() => v ? _selectedCategories.add(cat) : _selectedCategories.remove(cat)),
                          selectedColor: AppColors.oliveLight,
                          checkmarkColor: AppColors.olive,
                        );
                      }).toList(),
                    ),
                  ],

                  // Staff: permission assignment
                  if (_role == StaffRole.staff) ...[
                    const SizedBox(height: 16),
                    Text('Permissions', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    _PermissionToggle(
                      label: 'Manage Orders',
                      value: _permissions.canManageOrders,
                      onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageOrders: v)),
                    ),
                    _PermissionToggle(
                      label: 'Manage Takeaway',
                      value: _permissions.canManageTakeaway,
                      onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageTakeaway: v)),
                    ),
                    _PermissionToggle(
                      label: 'Manage Inventory',
                      value: _permissions.canManageInventory,
                      onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageInventory: v)),
                    ),
                    _PermissionToggle(
                      label: 'View Reports',
                      value: _permissions.canViewReports,
                      onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canViewReports: v)),
                    ),
                    _PermissionToggle(
                      label: 'Manage Menu',
                      value: _permissions.canManageMenu,
                      onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageMenu: v)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _create,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditStaffSheet extends ConsumerStatefulWidget {
  final StaffModel staff;
  const _EditStaffSheet({required this.staff});

  @override
  ConsumerState<_EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends ConsumerState<_EditStaffSheet> {
  late Set<String> _selectedCategories;
  late StaffPermissions _permissions;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.staff.assignedCategories);
    _permissions = widget.staff.permissions;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final updated = widget.staff.copyWith(
      assignedCategories: _selectedCategories.toList(),
      permissions: _permissions,
    );
    await ref.read(firestoreServiceProvider).updateStaff(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(widget.staff.name, style: AppTextStyles.titleLarge),
                Row(
                  children: [
                    _RoleBadge(role: widget.staff.role),
                    const SizedBox(width: 8),
                    Text(widget.staff.email, style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.staff.isAdmin) ...[
                    Text('Assigned Categories', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kInventoryCategories.map((cat) {
                        final sel = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: sel,
                          onSelected: (v) => setState(() => v ? _selectedCategories.add(cat) : _selectedCategories.remove(cat)),
                          selectedColor: AppColors.oliveLight,
                          checkmarkColor: AppColors.olive,
                        );
                      }).toList(),
                    ),
                  ],

                  if (!widget.staff.isSuperAdmin) ...[
                    const SizedBox(height: 16),
                    Text('Permissions', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    _PermissionToggle(label: 'Manage Orders', value: _permissions.canManageOrders, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageOrders: v))),
                    _PermissionToggle(label: 'Manage Takeaway', value: _permissions.canManageTakeaway, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageTakeaway: v))),
                    _PermissionToggle(label: 'Manage Inventory', value: _permissions.canManageInventory, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageInventory: v))),
                    _PermissionToggle(label: 'View Reports', value: _permissions.canViewReports, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canViewReports: v))),
                    _PermissionToggle(label: 'Manage Menu', value: _permissions.canManageMenu, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageMenu: v))),
                    _PermissionToggle(label: 'Manage Vendors', value: _permissions.canManageVendors, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canManageVendors: v))),
                    _PermissionToggle(label: 'Approve Procurement', value: _permissions.canApproveProcurement, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(canApproveProcurement: v))),
                  ],

                  const SizedBox(height: 16),
                  if (widget.staff.isActive)
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(firestoreServiceProvider).deactivateStaff(widget.staff.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                      child: const Text('Deactivate Account'),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label, style: AppTextStyles.bodyMedium),
    value: value,
    onChanged: onChanged,
    activeColor: AppColors.olive,
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}
