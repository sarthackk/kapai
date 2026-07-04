import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rewards', style: AppTextStyles.displayMedium),
                const SizedBox(height: 20),
                // Beans count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${user?.beans ?? 0}',
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.charcoal, height: 1)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('beans', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMid)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mossLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${user?.tier.label ?? 'Sprout'} Tier',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.moss),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress bar
                _TierProgress(user: user),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiers
                Text('Loyalty Tiers', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                _TierCard(
                  tier: LoyaltyTier.sprout,
                  beans: '0–199',
                  perks: ['5% off every order', 'Birthday bonus beans'],
                  current: user?.tier == LoyaltyTier.sprout,
                ),
                const SizedBox(height: 8),
                _TierCard(
                  tier: LoyaltyTier.brew,
                  beans: '200–499',
                  perks: ['10% off every order', '2× beans on weekends', 'Priority queue'],
                  current: user?.tier == LoyaltyTier.brew,
                ),
                const SizedBox(height: 8),
                _TierCard(
                  tier: LoyaltyTier.roast,
                  beans: '500+',
                  perks: ['15% off every order', '3× beans always', 'Free item on birthday', 'Early access to new menu'],
                  current: user?.tier == LoyaltyTier.roast,
                ),
                const SizedBox(height: 24),

                // How to earn
                Text('How to earn beans', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.creamDark),
                  ),
                  child: Column(
                    children: [
                      _EarnRow(icon: Icons.coffee_outlined, label: 'Every order', value: '1 bean / ₹10'),
                      _EarnRow(icon: Icons.cake_outlined, label: 'Birthday', value: '50 bonus beans'),
                      _EarnRow(icon: Icons.wb_sunny_outlined, label: 'Happy Hour', value: '2× beans', isLast: true),
                    ],
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

class _TierProgress extends StatelessWidget {
  final UserModel? user;
  const _TierProgress({this.user});

  @override
  Widget build(BuildContext context) {
    final beans = user?.beans ?? 0;
    final tier = user?.tier ?? LoyaltyTier.sprout;
    if (tier == LoyaltyTier.roast) {
      return Text('Maximum tier reached!', style: AppTextStyles.bodySmall.copyWith(color: AppColors.moss));
    }
    final nextTier = tier == LoyaltyTier.sprout ? LoyaltyTier.brew : LoyaltyTier.roast;
    final nextMin = nextTier.minBeans;
    final curMin = tier.minBeans;
    final progress = ((beans - curMin) / (nextMin - curMin)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.creamDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.moss),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text('${nextMin - beans} beans to ${nextTier.label}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid)),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final LoyaltyTier tier;
  final String beans;
  final List<String> perks;
  final bool current;

  const _TierCard({required this.tier, required this.beans, required this.perks, this.current = false});

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      LoyaltyTier.sprout => AppColors.moss,
      LoyaltyTier.brew   => AppColors.terracotta,
      LoyaltyTier.roast  => AppColors.olive,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: current ? AppColors.oliveLight : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: current ? AppColors.olive : AppColors.creamDark, width: current ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tier.label, style: AppTextStyles.titleMedium.copyWith(color: color)),
              const SizedBox(width: 8),
              Text(beans, style: AppTextStyles.bodySmall),
              if (current) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.olive, borderRadius: BorderRadius.circular(8)),
                  child: Text('Current', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...perks.map((perk) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: color),
                const SizedBox(width: 6),
                Text(perk, style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoal)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _EarnRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.moss),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.labelLarge.copyWith(color: AppColors.moss)),
        ],
      ),
    );
  }
}
