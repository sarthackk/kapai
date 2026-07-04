import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  static const _tabs = [
    (path: '/app/home',    icon: Icons.home_outlined,       activeIcon: Icons.home,         label: 'Home'),
    (path: '/app/menu',    icon: Icons.menu_book_outlined,  activeIcon: Icons.menu_book,    label: 'Menu'),
    (path: '/app/orders',  icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    (path: '/app/rewards', icon: Icons.local_cafe_outlined, activeIcon: Icons.local_cafe,   label: 'Rewards'),
    (path: '/app/profile', icon: Icons.person_outline,      activeIcon: Icons.person,       label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.creamDark)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: _tabs.map((tab) {
                final active = location.startsWith(tab.path);
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (active)
                          Container(
                            width: 20, height: 2,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.olive,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                        Icon(
                          active ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: active ? AppColors.olive : AppColors.textLight,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: active ? AppColors.olive : AppColors.textLight,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
