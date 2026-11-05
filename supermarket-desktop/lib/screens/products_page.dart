import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.api, required this.isAdmin});

  final ApiClient api;
  final bool isAdmin;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const _pageSize = 15;

  final _search = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<Product> _items = const [];
  List<Category> _categories = const [];
  List<Supplier> _suppliers = const [];
  int _total = 0;
  int _page = 1;
  bool _lowOnly = false;
  String? _categoryId;

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
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _page = 1;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categoriesFuture = widget.api.categories();
      final suppliersFuture = widget.api.suppliers();
      final productsFuture = widget.api.products(
        q: _search.text,
        category: _categoryId,
        lowStock: _lowOnly,
        page: _page,
        limit: _pageSize,
      );
      final categories = await categoriesFuture;
      final suppliers = await suppliersFuture;
      final products = await productsFuture;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _items = products.items;
        _total = products.total;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) _error = error.toString();
      });
      if (_items.isNotEmpty) toast(context, error.toString(), error: true);
    }
  }

  int get _pageCount => _total == 0 ? 1 : ((_total + _pageSize - 1) ~/ _pageSize);

  Future<void> _openEditor({Product? existing}) async {
    if (_categories.isEmpty || _suppliers.isEmpty) {
      toast(
        context,
        'Add a category and a supplier before creating a product.',
        error: true,
      );
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductDialog(
        api: widget.api,
        existing: existing,
        categories: _categories,
        suppliers: _suppliers,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _restock(Product product) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _RestockDialog(api: widget.api, product: product),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Product product) async {
    final ok = await confirm(
      context,
      title: 'Delete product',
      message: 'Delete ${product.name}?',
    );
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteProduct(product.id);
      if (!mounted) return;
      toast(context, 'Product deleted');
      await _load();
    } catch (error) {
      if (!mounted) return;
      toast(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Products',
      subtitle: '$_total products · search matches whole words',
      actions: [
        if (widget.isAdmin)
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New product'),
          ),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search name',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: AppDropdown<String?>(
                  value: _categoryId,
                  hint: 'All categories',
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    for (final category in _categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                      _page = 1;
                    });
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Low stock'),
                selected: _lowOnly,
                onSelected: (value) {
                  setState(() {
                    _lowOnly = value;
                    _page = 1;
                  });
                  _load();
                },
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 12),
          Expanded(
            child: _error != null
                ? ErrorRetry(message: _error!, onRetry: _load)
                : Panel(
                    padding: EdgeInsets.zero,
                    child: _items.isEmpty
                        ? const EmptyHint(message: 'No products match.')
                        : Column(
                            children: [
                              const _Header(),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _items.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final product = _items[index];
                                    return _ProductRow(
                                      product: product,
                                      isAdmin: widget.isAdmin,
                                      onEdit: () => _openEditor(existing: product),
                                      onRestock: () => _restock(product),
                                      onDelete: () => _delete(product),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Page $_page of $_pageCount'),
              IconButton(
                onPressed: _page > 1
                    ? () {
                        setState(() => _page -= 1);
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _page < _pageCount
                    ? () {
                        setState(() => _page += 1);
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Product', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Category', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Price', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Stock', style: _headerStyle)),
          SizedBox(width: 132),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.isAdmin,
    required this.onEdit,
    required this.onRestock,
    required this.onDelete,
  });

  final Product product;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onRestock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (product.discountPercentage > 0)
                  Text(
                    '${product.discountPercentage.toStringAsFixed(0)}% off',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(product.category.label)),
          Expanded(flex: 2, child: Text(money(product.price))),
          Expanded(
            flex: 2,
            child: Text(
              '${product.stock}',
              style: TextStyle(
                color: product.isLowStock ? AppColors.citrus : AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: isAdmin
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Restock',
                        onPressed: onRestock,
                        icon: const Icon(Icons.add_box_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.api,
    required this.categories,
    required this.suppliers,
    this.existing,
  });

  final ApiClient api;
  final List<Category> categories;
  final List<Supplier> suppliers;
  final Product? existing;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _quantity;
  late final TextEditingController _discount;
  late final TextEditingController _threshold;
  String? _categoryId;
  String? _supplierId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _price = TextEditingController(
      text: existing == null ? '' : existing.price.toString(),
    );
    _stock = TextEditingController(
      text: existing == null ? '' : '${existing.stock}',
    );
    _quantity = TextEditingController(
      text: existing == null ? '' : '${existing.quantity}',
    );
    _discount = TextEditingController(
      text: existing == null ? '0' : existing.discountPercentage.toString(),
    );
    _threshold = TextEditingController(
      text: existing == null ? '10' : '${existing.lowStockThreshold}',
    );
    if (existing != null &&
        widget.categories.any((item) => item.id == existing.category.id)) {
      _categoryId = existing.category.id;
    }
    if (existing != null &&
        widget.suppliers.any((item) => item.id == existing.supplier.id)) {
      _supplierId = existing.supplier.id;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _quantity.dispose();
    _discount.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    final quantity = int.tryParse(_quantity.text.trim());
    final discount = _discount.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_discount.text.trim());
    final threshold = _threshold.text.trim().isEmpty
        ? 10
        : int.tryParse(_threshold.text.trim());

    String? error;
    if (name.isEmpty) {
      error = 'Name is required';
    } else if (price == null || price < 0) {
      error = 'Enter a price of 0 or more';
    } else if (stock == null || stock < 0 || quantity == null || quantity < 0) {
      error = 'Stock and quantity must be whole numbers, 0 or more';
    } else if (discount == null || discount < 0 || discount > 100) {
      error = 'Discount must be between 0 and 100';
    } else if (threshold == null || threshold < 0) {
      error = 'Low-stock threshold must be 0 or more';
    } else if (_categoryId == null || _supplierId == null) {
      error = 'Choose a category and a supplier';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'name': name,
      'description': _description.text.trim(),
      'price': price,
      'stock': stock,
      'quantity': quantity,
      'discountPercentage': discount,
      'lowStockThreshold': threshold,
      'category': _categoryId,
      'supplier': _supplierId,
    };
    try {
      if (widget.existing == null) {
        await widget.api.createProduct(body);
      } else {
        await widget.api.updateProduct(widget.existing!.id, body);
      }
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
    return AlertDialog(
      title: Text(widget.existing == null ? 'New product' : 'Edit product'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _discount,
                      decoration: const InputDecoration(labelText: 'Discount %'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _quantity,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        helperText: 'Stored with stock',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _threshold,
                      decoration: const InputDecoration(labelText: 'Low at'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                value: _categoryId,
                hint: 'Category',
                items: [
                  for (final category in widget.categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                value: _supplierId,
                hint: 'Supplier',
                items: [
                  for (final supplier in widget.suppliers)
                    DropdownMenuItem(
                      value: supplier.id,
                      child: Text(supplier.name),
                    ),
                ],
                onChanged: (value) => setState(() => _supplierId = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

class _RestockDialog extends StatefulWidget {
  const _RestockDialog({required this.api, required this.product});

  final ApiClient api;
  final Product product;

  @override
  State<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<_RestockDialog> {
  final _quantity = TextEditingController(text: '1');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity < 1) {
      setState(() => _error = 'Enter a quantity of 1 or more');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.restock(widget.product.id, quantity);
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
    return AlertDialog(
      title: Text('Restock ${widget.product.name}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('On hand: ${widget.product.stock}'),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Add quantity'),
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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Add stock'),
        ),
      ],
    );
  }
}
