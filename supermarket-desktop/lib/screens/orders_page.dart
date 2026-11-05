import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _loading = true;
  String? _error;
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
      final orders = await widget.api.orders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _open(ShopOrder order) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _OrderDialog(api: widget.api, order: order),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Orders',
      subtitle: 'Cashiers see their own sales. Admins see every sale.',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : Panel(
              padding: EdgeInsets.zero,
              child: _orders.isEmpty
                  ? const EmptyHint(message: 'No orders yet.')
                  : ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return ListTile(
                          onTap: () => _open(order),
                          title: Text(
                            money(order.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${order.cashier.label} · ${order.items.length} lines · ${whenLabel(order.createdAt)}',
                          ),
                          trailing: StatusChip(status: order.status),
                        );
                      },
                    ),
            ),
    );
  }
}

class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.api, required this.order});

  final ApiClient api;
  final ShopOrder order;

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = orderStatuses.contains(widget.order.status)
        ? widget.order.status
        : 'pending';
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateOrder(widget.order.id, {'status': _status});
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete order',
      message: 'Delete this order? Stock is not returned.',
    );
    if (!ok || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.deleteOrder(widget.order.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return AlertDialog(
      title: Text('Order ${money(order.total)}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.cashier.label} · ${whenLabel(order.createdAt)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item.quantity} × ${item.name}'),
                          ),
                          Text(money(item.lineTotal)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Text('Subtotal ${money(order.subtotal)}'),
            Text('Order discount ${order.orderDiscountPercent.toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            AppDropdown<String>(
              value: _status,
              items: [
                for (final status in orderStatuses)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _delete,
          child: const Text(
            'Delete',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Update status'),
        ),
      ],
    );
  }
}
