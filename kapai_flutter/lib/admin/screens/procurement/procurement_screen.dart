import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/procurement_request_model.dart';
import '../../../core/models/inventory_item_model.dart';
import '../../../core/models/vendor_model.dart';

final _procurementProvider = StreamProvider.family<List<ProcurementRequestModel>, ProcurementStatus?>(
  (ref, status) => ref.watch(firestoreServiceProvider).watchProcurementRequests(status: status),
);

final _vendorsProvider = StreamProvider<List<VendorModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchVendors(),
);

final _allInventoryProvider = StreamProvider<List<InventoryItemModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchInventory(),
);

final _procurementTabProvider = StateProvider<ProcurementStatus?>((ref) => ProcurementStatus.pending);

class ProcurementScreen extends ConsumerWidget {
  const ProcurementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProfileProvider).valueOrNull;
    final selectedStatus = ref.watch(_procurementTabProvider);
    final requestsAsync = ref.watch(_procurementProvider(selectedStatus));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Procurement', style: AppTextStyles.displaySmall)),
                    if (staff?.can('manageInventory') ?? false)
                      FilledButton.icon(
                        onPressed: () => _showNewRequestSheet(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Request'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusTab(label: 'Pending', status: ProcurementStatus.pending, selected: selectedStatus),
                      _StatusTab(label: 'Approved', status: ProcurementStatus.approved, selected: selectedStatus),
                      _StatusTab(label: 'Ordered', status: ProcurementStatus.ordered, selected: selectedStatus),
                      _StatusTab(label: 'Received', status: ProcurementStatus.received, selected: selectedStatus),
                      _StatusTab(label: 'All', status: null, selected: selectedStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // List
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text('No requests', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _RequestCard(
                    request: requests[i],
                    staff: staff,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewRequestSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewRequestSheet(),
    );
  }
}

class _StatusTab extends ConsumerWidget {
  final String label;
  final ProcurementStatus? status;
  final ProcurementStatus? selected;

  const _StatusTab({required this.label, required this.status, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = selected == status;
    return GestureDetector(
      onTap: () => ref.read(_procurementTabProvider.notifier).state = status,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.olive : AppColors.creamDark),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: active ? Colors.white : AppColors.charcoal),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final ProcurementRequestModel request;
  final StaffModel? staff;

  const _RequestCard({required this.request, this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = staff?.isSuperAdmin ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Expanded(child: Text(request.itemName, style: AppTextStyles.titleMedium)),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.category, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),

          // Details
          Row(
            children: [
              _Detail(label: 'Qty', value: '${request.quantity} ${request.unit}'),
              const SizedBox(width: 24),
              _Detail(label: 'Urgency', value: request.urgency.label),
              const SizedBox(width: 24),
              _Detail(label: 'By', value: request.requestedByName),
            ],
          ),

          if (request.vendorName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 14, color: AppColors.textMid),
                const SizedBox(width: 4),
                Text(request.vendorName!, style: AppTextStyles.bodySmall),
              ],
            ),
          ],

          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.notes!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid)),
          ],

          const SizedBox(height: 4),
          Text(
            DateFormat('d MMM y, h:mm a').format(request.createdAt),
            style: AppTextStyles.labelSmall,
          ),

          // Actions for super admin
          if (isSuperAdmin && request.status == ProcurementStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(firestoreServiceProvider).rejectProcurementRequest(request.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Find vendor for category
                      final vendors = ref.read(_vendorsProvider).valueOrNull ?? [];
                      final vendor = vendors.firstWhere(
                        (v) => v.categories.contains(request.category),
                        orElse: () => VendorModel(id: '', name: '', contactName: '', phone: '', categories: []),
                      );
                      if (staff != null) {
                        await ref.read(firestoreServiceProvider).approveProcurementRequest(
                          request.id,
                          staff.id,
                          staff.name,
                        );
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],

          if (isSuperAdmin && request.status == ProcurementStatus.approved) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(firestoreServiceProvider).markProcurementOrdered(request.id),
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('Mark as Ordered'),
              ),
            ),
          ],

          if (request.status == ProcurementStatus.ordered) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(firestoreServiceProvider).markProcurementReceived(request.id),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Mark as Received'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.labelSmall),
      Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final ProcurementStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ProcurementStatus.pending  => (AppColors.warningLight, AppColors.warning),
      ProcurementStatus.approved => (AppColors.oliveLight, AppColors.olive),
      ProcurementStatus.ordered  => (AppColors.sageLight, AppColors.sage),
      ProcurementStatus.received => (AppColors.successLight, AppColors.success),
      ProcurementStatus.rejected => (AppColors.errorLight, AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: AppTextStyles.labelSmall.copyWith(color: fg)),
    );
  }
}

class _NewRequestSheet extends ConsumerStatefulWidget {
  const _NewRequestSheet();

  @override
  ConsumerState<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<_NewRequestSheet> {
  InventoryItemModel? _selectedItem;
  final _quantityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ProcurementUrgency _urgency = ProcurementUrgency.medium;
  bool _loading = false;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedItem == null || _quantityCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final staff = ref.read(staffProfileProvider).valueOrNull;
    final qty = double.tryParse(_quantityCtrl.text) ?? 0;

    // Find vendor for this category
    final vendors = ref.read(_vendorsProvider).valueOrNull ?? [];
    final vendor = vendors.where((v) => v.categories.contains(_selectedItem!.category)).firstOrNull;

    final req = ProcurementRequestModel(
      id: '',
      itemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      category: _selectedItem!.category,
      quantity: qty,
      unit: _selectedItem!.unit,
      urgency: _urgency,
      status: ProcurementStatus.pending,
      requestedBy: staff?.id ?? '',
      requestedByName: staff?.name ?? '',
      vendorId: vendor?.id,
      vendorName: vendor?.name,
      notes: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).createProcurementRequest(req);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.read(staffProfileProvider).valueOrNull;
    final inventoryAsync = ref.watch(_allInventoryProvider);
    final items = inventoryAsync.valueOrNull ?? [];

    // Filter by assigned categories for non-super-admin
    final filteredItems = staff?.isSuperAdmin ?? false
        ? items
        : items.where((i) => staff?.assignedCategories.contains(i.category) ?? false).toList();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Procurement Request', style: AppTextStyles.titleLarge),
            const SizedBox(height: 20),

            // Item selector
            DropdownButtonFormField<InventoryItemModel>(
              value: _selectedItem,
              decoration: const InputDecoration(labelText: 'Select item'),
              items: filteredItems.map((item) => DropdownMenuItem(
                value: item,
                child: Text('${item.name} (${item.category})'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedItem = v),
            ),
            const SizedBox(height: 12),

            if (_selectedItem != null)
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Quantity needed (${_selectedItem!.unit})'),
              ),
            const SizedBox(height: 12),

            // Urgency
            Row(
              children: ProcurementUrgency.values.map((u) {
                final selected = _urgency == u;
                final color = switch (u) {
                  ProcurementUrgency.low => AppColors.success,
                  ProcurementUrgency.medium => AppColors.warning,
                  ProcurementUrgency.high => AppColors.error,
                };
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: u != ProcurementUrgency.high ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _urgency = u),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.12) : AppColors.cream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? color : AppColors.creamDark),
                        ),
                        child: Center(
                          child: Text(u.label, style: AppTextStyles.labelLarge.copyWith(color: selected ? color : AppColors.textMid)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || _selectedItem == null) ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
