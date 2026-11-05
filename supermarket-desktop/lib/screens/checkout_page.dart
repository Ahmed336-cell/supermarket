import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1})
    : discountPercent = product.discountPercentage;

  final Product product;
  int quantity;
  double discountPercent;

  double get lineTotalValue =>
      lineTotal(product.price, quantity, discountPercent);
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _search = TextEditingController();
  final _orderDiscount = TextEditingController(text: '0');
  final _cart = <CartLine>[];
  Timer? _debounce;
  bool _loading = true;
  bool _placing = false;
  String? _error;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _orderDiscount.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await widget.api.products(q: _search.text, limit: 30);
      if (!mounted) return;
      setState(() {
        _products = page.items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _add(Product product) {
    if (product.stock <= 0) {
      toast(context, '${product.name} is out of stock', error: true);
      return;
    }
    final index = _cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      setState(() => _cart.add(CartLine(product: product)));
      return;
    }
    if (_cart[index].quantity >= product.stock) {
      toast(context, 'Only ${product.stock} in stock', error: true);
      return;
    }
    setState(() => _cart[index].quantity += 1);
  }

  double get _subtotal =>
      _cart.fold<double>(0, (sum, line) => sum + line.lineTotalValue);

  double? get _discount {
    final text = _orderDiscount.text.trim();
    if (text.isEmpty) return 0;
    return double.tryParse(text);
  }

  Future<void> _place() async {
    if (_cart.isEmpty) {
      toast(context, 'Add a product first', error: true);
      return;
    }
    final discount = _discount;
    if (discount == null || discount < 0 || discount > 100) {
      toast(context, 'Order discount must be between 0 and 100', error: true);
      return;
    }
    setState(() => _placing = true);
    try {
      final placed = await widget.api.createOrder(
        orderDiscountPercent: discount,
        items: [
          for (final line in _cart)
            <String, dynamic>{
              'product': line.product.id,
              'quantity': line.quantity,
              'discountPercent': line.discountPercent,
            },
        ],
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _orderDiscount.text = '0';
        _placing = false;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order placed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total ${money(placed.order.total)}'),
              if (placed.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Low stock',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final warning in placed.warnings) Text(warning),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _placing = false);
      toast(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = _discount ?? 0;
    final total = _discount == null ? _subtotal : orderTotal(_subtotal, discount);
    return PageFrame(
      title: 'Checkout',
      subtitle: 'The API prices the sale and reduces stock',
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Panel(
                    padding: EdgeInsets.zero,
                    child: _error != null
                        ? ErrorRetry(message: _error!, onRetry: _load)
                        : _loading && _products.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _products.isEmpty
                        ? const EmptyHint(message: 'No products match.')
                        : ListView.separated(
                            itemCount: _products.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final match = _cart.indexWhere(
                                (line) => line.product.id == product.id,
                              );
                              final inCart = match == -1
                                  ? 0
                                  : _cart[match].quantity;
                              return ListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                  '${money(product.price)} · ${product.stock} in stock',
                                ),
                                trailing: FilledButton(
                                  onPressed: product.stock <= 0
                                      ? null
                                      : () => _add(product),
                                  child: Text(inCart == 0 ? 'Add' : 'Add ($inCart)'),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _cart.isEmpty
                        ? const EmptyHint(message: 'Cart is empty.')
                        : ListView(
                            children: [
                              for (final line in _cart)
                                _CartTile(
                                  key: ValueKey(line.product.id),
                                  line: line,
                                  onChanged: () => setState(() {}),
                                  onRemove: () =>
                                      setState(() => _cart.remove(line)),
                                ),
                            ],
                          ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _orderDiscount,
                    decoration: const InputDecoration(
                      labelText: 'Order discount %',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text('Subtotal ${money(_subtotal)}'),
                  Text(
                    'Total ${money(total)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _placing ? null : _place,
                    child: Text(_placing ? 'Placing…' : 'Place order'),
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

class _CartTile extends StatefulWidget {
  const _CartTile({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<_CartTile> {
  late final TextEditingController _discount;

  @override
  void initState() {
    super.initState();
    _discount = TextEditingController(
      text: widget.line.discountPercent.toString(),
    );
  }

  @override
  void dispose() {
    _discount.dispose();
    super.dispose();
  }

  void _setQty(int next) {
    if (next < 1 || next > widget.line.product.stock) return;
    widget.line.quantity = next;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _setQty(line.quantity - 1),
                icon: const Icon(Icons.remove),
              ),
              Text('${line.quantity}'),
              IconButton(
                onPressed: () => _setQty(line.quantity + 1),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _discount,
                  decoration: const InputDecoration(
                    labelText: '%',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0 || parsed > 100) return;
                    line.discountPercent = parsed;
                    widget.onChanged();
                  },
                ),
              ),
              const Spacer(),
              Text(money(line.lineTotalValue)),
            ],
          ),
        ],
      ),
    );
  }
}
