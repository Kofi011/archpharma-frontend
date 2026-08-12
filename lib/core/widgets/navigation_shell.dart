import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../theme/app_colors.dart';

class NavigationShell extends ConsumerWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/sales')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/purchases')) return 3;
    if (location.startsWith('/customers')) return 4;
    if (location.startsWith('/suppliers')) return 5;
    if (location.startsWith('/reports')) return 6;
    if (location.startsWith('/settings')) return 7;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/sales');
        break;
      case 2:
        context.go('/inventory');
        break;
      case 3:
        context.go('/purchases');
        break;
      case 4:
        context.go('/customers');
        break;
      case 5:
        context.go('/suppliers');
        break;
      case 6:
        context.go('/reports');
        break;
      case 7:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final userSession = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      // Desktop Navigation Layout (Sidebar + Content)
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 260,
              color: AppColors.sidebarLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Header (Clickable to refresh / reset to Dashboard)
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/images/archpharma_logo.png',
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.local_pharmacy, color: AppColors.primary, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'ArchPharma',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Padding(
                            padding: EdgeInsets.only(left: 40),
                            child: Text(
                              'Wholesale ERP',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stitch Primary Action Button "+ New Sale"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/sales/new-invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text(
                          'New Sale',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Options
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildSidebarItem(
                          icon: Icons.space_dashboard_rounded,
                          label: 'Dashboard',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onItemTapped(0, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.receipt_long_rounded,
                          label: 'Sales',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onItemTapped(1, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.warehouse_rounded,
                          label: 'Inventory',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onItemTapped(2, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.shopping_cart_checkout_rounded,
                          label: 'Purchases',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onItemTapped(3, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.business_center_rounded,
                          label: 'Customers',
                          isSelected: selectedIndex == 4,
                          onTap: () => _onItemTapped(4, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.local_shipping_rounded,
                          label: 'Suppliers',
                          isSelected: selectedIndex == 5,
                          onTap: () => _onItemTapped(5, context),
                        ),
                        _buildSidebarItem(
                          icon: Icons.analytics_rounded,
                          label: 'Reports',
                          isSelected: selectedIndex == 6,
                          onTap: () => _onItemTapped(6, context),
                        ),
                        const Divider(height: 30),
                        _buildSidebarItem(
                          icon: Icons.tune_rounded,
                          label: 'System Settings',
                          isSelected: selectedIndex == 7,
                          onTap: () => _onItemTapped(7, context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 18,
                          child: Icon(Icons.person_outline, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userSession?.name ?? 'User',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                userSession?.role.name.toUpperCase() ?? 'ROLE',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Logout',
                          onPressed: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.borderLight),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile/Tablet Scaffold without Drawer to prevent double AppBar description & right overflows
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex == 0
            ? 0
            : selectedIndex == 1
                ? 1
                : (selectedIndex == 2 || selectedIndex == 3)
                    ? 2
                    : (selectedIndex == 4 || selectedIndex == 5)
                        ? 3
                        : selectedIndex == 6
                            ? 4
                            : 0,
        onTap: (idx) {
          switch (idx) {
            case 0:
              _onItemTapped(0, context);
              break;
            case 1:
              _onItemTapped(1, context);
              break;
            case 2:
              _onItemTapped(2, context);
              break;
            case 3:
              _onItemTapped(4, context);
              break;
            case 4:
              _onItemTapped(6, context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined),
            activeIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse_rounded),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sales/new-invoice'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of ArchPharma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
