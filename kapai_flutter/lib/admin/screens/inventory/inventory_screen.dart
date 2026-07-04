import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/inventory_item_model.dart';
import '../../../core/models/inventory_check_model.dart';
import '../../../core/models/staff_model.dart';

final _inventoryProvider = StreamProvider.family<List<InventoryItemModel>, String?>(
  (ref, category) => ref.watch(firestoreServiceProvider).watchInventory(category: category),
);

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProfileProvider);
    final staff = staffAsync.valueOrNull;
    final selectedCategory = ref.watch(_selectedCategoryProvider);

    // Filter categories based on role
    final categories = staff?.isSuperAdmin ?? false
        ? kInventoryCategories
        : (staff?.assignedCategories ?? []);

    final inventoryAsync = ref.watch(_inventoryProvider(selectedCategory));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Inventory', style: AppTextStyles.displaySmall)),
                    if (staff?.isSuperAdmin ?? false)
                      FilledButton.icon(
                        onPressed: () => _showAddItemSheet(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.olive,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: selectedCategory == null,
                        onTap: () => ref.read(_selectedCategoryProvider.notifier).state = null,
                      ),
                      ...categories.map((c) => _CategoryChip(
                        label: c,
                        selected: selectedCategory == c,
                        onTap: () => ref.read(_selectedCategoryProvider.notifier).state = c,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text('No items found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
                  );
                }
                // Group by category
                final grouped = <String, List<InventoryItemModel>>{};
                for (final item in items) {
                  grouped.putIfAbsent(item.category, () => []).add(item);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) => _CategorySection(
                    category: entry.key,
                    items: entry.value,
                    staff: staff,
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddItemSheet(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.olive : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.olive : AppColors.creamDark),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? Colors.white : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<InventoryItemModel> items;
  final StaffModel? staff;

  const _CategorySection({required this.category, required this.items, this.staff});

  @override
  Widget build(BuildContext context) {
    final lowStockCount = items.where((i) => i.isLowStock).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Text(category, style: AppTextStyles.titleMedium),
              const SizedBox(width: 8),
              Text('${items.length}', style: AppTextStyles.bodySmall),
              if (lowStockCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$lowStockCount low', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.creamDark),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return _InventoryItemRow(item: e.value, isLast: isLast, staff: staff);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InventoryItemRow extends ConsumerWidget {
  final InventoryItemModel item;
  final bool isLast;
  final StaffModel? staff;

  const _InventoryItemRow({required this.item, required this.isLast, this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showStockUpdateSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(item.unit, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.currentStock} ${item.unit}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: item.isLowStock ? AppColors.error : AppColors.charcoal,
                  ),
                ),
                if (item.isLowStock)
                  Text('Low stock', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  void _showStockUpdateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockUpdateSheet(item: item),
    );
  }
}

class _StockUpdateSheet extends ConsumerStatefulWidget {
  final InventoryItemModel item;
  const _StockUpdateSheet({required this.item});

  @override
  ConsumerState<_StockUpdateSheet> createState() => _StockUpdateSheetState();
}

class _StockUpdateSheetState extends ConsumerState<_StockUpdateSheet> {
  final _quantityCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  CheckType _checkType = CheckType.morning;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _quantityCtrl.text = widget.item.currentStock.toString();
    // Auto-select check type based on time
    _checkType = DateTime.now().hour < 14 ? CheckType.morning : CheckType.eod;
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newQty = double.tryParse(_quantityCtrl.text);
    if (newQty == null) return;
    setState(() => _loading = true);

    final staff = ref.read(staffProfileProvider).valueOrNull;
    final adjustment = newQty - widget.item.currentStock;

    await ref.read(firestoreServiceProvider).updateStockQuantity(
      widget.item.id,
      newQty,
      adjustment,
      staff?.id ?? '',
      staff?.name ?? '',
      _checkType,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      category: widget.item.category,
      itemName: widget.item.name,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            // Handle
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            Text(widget.item.name, style: AppTextStyles.titleLarge),
            Text(widget.item.category, style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),

            // Check type toggle
            Row(
              children: CheckType.values.map((t) {
                final selected = _checkType == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t == CheckType.morning ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _checkType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.oliveLight : AppColors.cream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? AppColors.moss : AppColors.creamDark),
                        ),
                        child: Center(
                          child: Text(t.label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: selected ? AppColors.olive : AppColors.textMid,
                            )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${widget.item.unit})',
                suffixText: widget.item.unit,
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Stock Count'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet();

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');
  final _thresholdCtrl = TextEditingController(text: '0');
  String _category = kInventoryCategories.first;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final item = InventoryItemModel(
      id: '',
      name: _nameCtrl.text.trim().toUpperCase(),
      category: _category,
      unit: _unitCtrl.text.trim(),
      currentStock: 0,
      minThreshold: double.tryParse(_thresholdCtrl.text) ?? 0,
    );

    await ref.read(firestoreServiceProvider).addInventoryItem(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Add Inventory Item', style: AppTextStyles.titleLarge),
            const SizedBox(height: 20),

            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item name')),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kInventoryCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: TextFormField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Unit (kg, pcs, ltr…)'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _thresholdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min threshold'))),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
