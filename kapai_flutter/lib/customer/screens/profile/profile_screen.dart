import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.olive,
                  child: Text(initial,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name.isNotEmpty == true ? user!.name : 'Guest',
                          style: AppTextStyles.displaySmall),
                      Text(user?.phone ?? '', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.mossLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(user?.tier.label ?? 'Sprout',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.moss)),
                          ),
                          const SizedBox(width: 8),
                          Text('${user?.beans ?? 0} beans', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Account
                _Section(items: [
                  _Item(icon: Icons.person_outline, label: 'Name', value: user?.name ?? '—'),
                  _Item(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? '—'),
                  _Item(icon: Icons.cake_outlined, label: 'Birthday', value: user?.birthday ?? 'Not set'),
                  _Item(icon: Icons.currency_rupee, label: 'Total Spent', value: '₹${user?.totalSpent.toStringAsFixed(0) ?? 0}', valueColor: AppColors.moss),
                ]),
                const SizedBox(height: 16),

                // Navigation
                _Section(items: [
                  _Item(icon: Icons.local_cafe_outlined, label: 'Rewards & Tiers', onTap: () => context.go('/app/rewards')),
                  _Item(icon: Icons.receipt_long_outlined, label: 'Order History', onTap: () => context.go('/app/orders')),
                  _Item(icon: Icons.help_outline, label: 'Help & Support'),
                ]),
                const SizedBox(height: 16),

                // Sign out
                GestureDetector(
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.creamDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 18, color: AppColors.textMid),
                        const SizedBox(width: 8),
                        Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMid)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<_Item> items;
  const _Section({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: AppColors.textMid),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.label, style: AppTextStyles.bodyMedium)),
                  if (item.value != null)
                    Text(item.value!, style: AppTextStyles.labelLarge.copyWith(color: item.valueColor ?? AppColors.charcoal))
                  else if (item.onTap != null)
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _Item({required this.icon, required this.label, this.value, this.valueColor, this.onTap});
}
