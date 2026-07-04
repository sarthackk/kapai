import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/menu_item_model.dart';

final _menuStreamProvider = StreamProvider<List<MenuItemModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchMenu(),
);

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(_menuStreamProvider);

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
                Expanded(child: Text('Menu', style: AppTextStyles.displaySmall)),
                FilledButton.icon(
                  onPressed: () => _showItemSheet(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                ),
              ],
            ),
          ),
          Expanded(
            child: menuAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final grouped = <String, List<MenuItemModel>>{};
                for (final item in items) {
                  grouped.putIfAbsent(item.category, () => []).add(item);
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((e) => _MenuCategory(
                    category: e.key,
                    items: e.value,
                    onTap: (item) => _showItemSheet(context, ref, item),
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showItemSheet(BuildContext context, WidgetRef ref, MenuItemModel? item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemSheet(item: item),
    );
  }
}

class _MenuCategory extends ConsumerWidget {
  final String category;
  final List<MenuItemModel> items;
  final ValueChanged<MenuItemModel> onTap;

  const _MenuCategory({required this.category, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(category, style: AppTextStyles.titleMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.creamDark),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return InkWell(
                onTap: () => onTap(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isVeg ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
                      Text('₹${item.price.toStringAsFixed(0)}', style: AppTextStyles.labelLarge),
                      const SizedBox(width: 10),
                      Switch.adaptive(
                        value: item.isAvailable,
                        activeColor: AppColors.olive,
                        onChanged: (v) => ref.read(firestoreServiceProvider).toggleMenuItemAvailability(item.id, v),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MenuItemSheet extends ConsumerStatefulWidget {
  final MenuItemModel? item;
  const _MenuItemSheet({this.item});

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _beansCtrl;
  late bool _isVeg;
  late bool _isAvailable;
  late bool _isBestseller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _descCtrl = TextEditingController(text: widget.item?.description ?? '');
    _priceCtrl = TextEditingController(text: widget.item?.price.toString() ?? '');
    _categoryCtrl = TextEditingController(text: widget.item?.category ?? '');
    _beansCtrl = TextEditingController(text: widget.item?.beansValue.toString() ?? '0');
    _isVeg = widget.item?.isVeg ?? true;
    _isAvailable = widget.item?.isAvailable ?? true;
    _isBestseller = widget.item?.isBestseller ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _categoryCtrl.dispose(); _beansCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final item = MenuItemModel(
      id: widget.item?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      category: _categoryCtrl.text.trim(),
      isVeg: _isVeg,
      isAvailable: _isAvailable,
      isBestseller: _isBestseller,
      beansValue: int.tryParse(_beansCtrl.text) ?? 0,
    );

    await ref.read(firestoreServiceProvider).saveMenuItem(item);
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
                Text(widget.item == null ? 'Add Menu Item' : 'Edit Item', style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Category'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _beansCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Beans earned per order')),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text('Veg', style: AppTextStyles.bodyMedium),
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v),
                    activeColor: AppColors.olive,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    title: Text('Available', style: AppTextStyles.bodyMedium),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeColor: AppColors.olive,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  SwitchListTile(
                    title: Text('Bestseller', style: AppTextStyles.bodyMedium),
                    value: _isBestseller,
                    onChanged: (v) => setState(() => _isBestseller = v),
                    activeColor: AppColors.olive,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.item == null ? 'Add Item' : 'Save Changes'),
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
