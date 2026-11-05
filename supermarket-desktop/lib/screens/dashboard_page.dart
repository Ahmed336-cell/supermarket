import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;
  int _productTotal = 0;
  int _categoryTotal = 0;
  int _supplierTotal = 0;
  List<Product> _low = const [];
  List<ShopOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final productsFuture = widget.api.products(limit: 1);
      final lowFuture = widget.api.products(lowStock: true, limit: 6);
      final ordersFuture = widget.api.orders();
      final categoriesFuture = widget.api.categories();
      final suppliersFuture = widget.api.suppliers();
      final products = await productsFuture;
      final low = await lowFuture;
      final orders = await ordersFuture;
      final categories = await categoriesFuture;
      final suppliers = await suppliersFuture;
      if (!mounted) return;
      setState(() {
        _productTotal = products.total;
        _low = low.items;
        _orders = orders;
        _categoryTotal = categories.length;
        _supplierTotal = suppliers.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _orders.fold<double>(0, (sum, order) => sum + order.total);
    return PageFrame(
      title: 'Dashboard',
      subtitle: 'Latest orders, stock, and catalog counts',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : Column(
              children: [
                Row(
                  children: [
                    _Stat(label: 'Products', value: '$_productTotal'),
                    const SizedBox(width: 12),
                    _Stat(label: 'Categories', value: '$_categoryTotal'),
                    const SizedBox(width: 12),
                    _Stat(label: 'Suppliers', value: '$_supplierTotal'),
                    const SizedBox(width: 12),
                    _Stat(
                      label: 'Order total',
                      value: money(revenue),
                      hint: '${_orders.length} latest',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Low stock',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _low.isEmpty
                                    ? const EmptyHint(
                                        message: 'Stock looks healthy.',
                                      )
                                    : ListView.separated(
                                        itemCount: _low.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final product = _low[index];
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(product.name),
                                            subtitle: Text(
                                              product.category.label,
                                            ),
                                            trailing: Text(
                                              '${product.stock} left',
                                              style: const TextStyle(
                                                color: AppColors.citrus,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent orders',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _orders.isEmpty
                                    ? const EmptyHint(message: 'No orders yet.')
                                    : ListView.separated(
                                        itemCount: _orders.length > 6
                                            ? 6
                                            : _orders.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final order = _orders[index];
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(money(order.total)),
                                            subtitle: Text(
                                              '${order.cashier.label} · ${whenLabel(order.createdAt)}',
                                            ),
                                            trailing: StatusChip(
                                              status: order.status,
                                            ),
                                          );
                                        },
                                      ),
                              ),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (hint != null)
              Text(hint!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
