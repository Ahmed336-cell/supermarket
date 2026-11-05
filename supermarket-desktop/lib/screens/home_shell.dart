import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'categories_page.dart';
import 'checkout_page.dart';
import 'dashboard_page.dart';
import 'orders_page.dart';
import 'products_page.dart';
import 'staff_page.dart';
import 'suppliers_page.dart';

class _Nav {
  const _Nav(this.label, this.icon, {this.adminOnly = false});

  final String label;
  final IconData icon;
  final bool adminOnly;
}

const _nav = [
  _Nav('Dashboard', Icons.space_dashboard_outlined),
  _Nav('Checkout', Icons.point_of_sale_outlined),
  _Nav('Orders', Icons.receipt_long_outlined),
  _Nav('Products', Icons.inventory_2_outlined),
  _Nav('Categories', Icons.category_outlined),
  _Nav('Suppliers', Icons.local_shipping_outlined),
  _Nav('Staff', Icons.badge_outlined, adminOnly: true),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};

  List<_Nav> _items(bool admin) {
    return _nav.where((item) => admin || !item.adminOnly).toList();
  }

  Widget _page(_Nav item, ApiClient api, bool admin) {
    switch (item.label) {
      case 'Dashboard':
        return DashboardPage(key: const ValueKey('dashboard'), api: api);
      case 'Checkout':
        return CheckoutPage(key: const ValueKey('checkout'), api: api);
      case 'Orders':
        return OrdersPage(key: const ValueKey('orders'), api: api);
      case 'Products':
        return ProductsPage(
          key: const ValueKey('products'),
          api: api,
          isAdmin: admin,
        );
      case 'Categories':
        return CategoriesPage(
          key: const ValueKey('categories'),
          api: api,
          isAdmin: admin,
        );
      case 'Suppliers':
        return SuppliersPage(
          key: const ValueKey('suppliers'),
          api: api,
          isAdmin: admin,
        );
      case 'Staff':
        return StaffPage(key: const ValueKey('staff'), api: api);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _logout() async {
    final ok = await confirm(
      context,
      title: 'Sign out',
      message: 'Leave the desk on this Mac?',
      action: 'Sign out',
      danger: false,
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user;
    if (user == null) return const SizedBox.shrink();

    final items = _items(state.isAdmin);
    final selectedIndex = _index >= items.length ? 0 : _index;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: ColoredBox(
              color: AppColors.mossDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Row(
                      children: [
                        _Mark(),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supermarket',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Desk',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = index == selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: Material(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() {
                                _index = index;
                                _visited.add(index);
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _logout,
                          child: const Text(
                            'Sign out',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                for (var i = 0; i < items.length; i++)
                  _visited.contains(i)
                      ? _page(items[i], state.api, state.isAdmin)
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.citrus,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
