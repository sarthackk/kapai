import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/inventory_item_model.dart';

final _vendorsStreamProvider = StreamProvider<List<VendorModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchVendors(),
);

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(_vendorsStreamProvider);

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
                Expanded(child: Text('Vendors', style: AppTextStyles.displaySmall)),
                FilledButton.icon(
                  onPressed: () => _showSheet(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Vendor'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                ),
              ],
            ),
          ),
          Expanded(
            child: vendorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (vendors) {
                if (vendors.isEmpty) {
                  return Center(child: Text('No vendors yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vendors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _VendorCard(vendor: vendors[i], onTap: () => _showSheet(context, ref, vendors[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, VendorModel? vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VendorSheet(vendor: vendor),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;
  const _VendorCard({required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.creamDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(vendor.name, style: AppTextStyles.titleMedium)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 4),
            Text('${vendor.contactName} · ${vendor.phone}', style: AppTextStyles.bodySmall),
            if (vendor.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: vendor.categories.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.oliveLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(c, style: AppTextStyles.labelSmall.copyWith(color: AppColors.olive)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VendorSheet extends ConsumerStatefulWidget {
  final VendorModel? vendor;
  const _VendorSheet({this.vendor});

  @override
  ConsumerState<_VendorSheet> createState() => _VendorSheetState();
}

class _VendorSheetState extends ConsumerState<_VendorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late Set<String> _selectedCategories;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vendor?.name ?? '');
    _contactCtrl = TextEditingController(text: widget.vendor?.contactName ?? '');
    _phoneCtrl = TextEditingController(text: widget.vendor?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.vendor?.email ?? '');
    _notesCtrl = TextEditingController(text: widget.vendor?.notes ?? '');
    _selectedCategories = Set.from(widget.vendor?.categories ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _contactCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final vendor = VendorModel(
      id: widget.vendor?.id ?? '',
      name: _nameCtrl.text.trim(),
      contactName: _contactCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      categories: _selectedCategories.toList(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await ref.read(firestoreServiceProvider).saveVendor(vendor);
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
                Text(widget.vendor == null ? 'Add Vendor' : 'Edit Vendor', style: AppTextStyles.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Vendor / company name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact person name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)')),
                  const SizedBox(height: 16),

                  Text('Supplies categories', style: AppTextStyles.labelLarge),
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

                  const SizedBox(height: 12),
                  TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.vendor == null ? 'Save Vendor' : 'Update Vendor'),
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
