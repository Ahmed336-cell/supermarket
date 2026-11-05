double lineTotal(double price, int quantity, double discountPercent) {
  return (price * quantity * (1 - discountPercent / 100) * 100).round() / 100;
}

double orderTotal(double subtotal, double discountPercent) {
  return (subtotal * (1 - discountPercent / 100) * 100).round() / 100;
}

double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class RefName {
  const RefName({required this.id, required this.name, this.email});

  final String id;
  final String name;
  final String? email;

  String get label {
    if (name.isNotEmpty) return name;
    if (email != null && email!.isNotEmpty) return email!;
    return '—';
  }

  static RefName parse(dynamic value) {
    if (value is Map) {
      return RefName(
        id: (value['_id'] ?? value['id'] ?? '').toString(),
        name: (value['name'] ?? '').toString(),
        email: value['email']?.toString(),
      );
    }
    return RefName(id: value?.toString() ?? '', name: '');
  }
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'cashier').toString(),
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.stock,
    required this.discountPercentage,
    required this.category,
    required this.supplier,
    required this.lowStockThreshold,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final int stock;
  final double discountPercentage;
  final RefName category;
  final RefName supplier;
  final int lowStockThreshold;

  bool get isLowStock => stock <= lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: toDouble(json['price']),
      quantity: toInt(json['quantity']),
      stock: toInt(json['stock']),
      discountPercentage: toDouble(json['discountPercentage']),
      category: RefName.parse(json['category']),
      supplier: RefName.parse(json['supplier']),
      lowStockThreshold: toInt(json['lowStockThreshold'] ?? 10),
    );
  }
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<Product> items;
  final int total;
  final int page;
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercentage,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double discountPercentage;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['product'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: toInt(json['quantity']),
      unitPrice: toDouble(json['unitPrice']),
      discountPercentage: toDouble(json['discountPercentage']),
      lineTotal: toDouble(json['lineTotal']),
    );
  }
}

const orderStatuses = [
  'pending',
  'confirmed',
  'shipped',
  'delivered',
  'cancelled',
];

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.cashier,
    required this.items,
    required this.subtotal,
    required this.orderDiscountPercent,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final RefName cashier;
  final List<OrderItem> items;
  final double subtotal;
  final double orderDiscountPercent;
  final double total;
  final String status;
  final DateTime? createdAt;

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ShopOrder(
      id: (json['_id'] ?? '').toString(),
      cashier: RefName.parse(json['cashier']),
      items: rawItems is List
          ? rawItems
                .map(
                  (item) => OrderItem.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const [],
      subtotal: toDouble(json['subtotal']),
      orderDiscountPercent: toDouble(json['orderDiscountPercent']),
      total: toDouble(json['total']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? '').toString(),
      )?.toLocal(),
    );
  }
}

class PlacedOrder {
  const PlacedOrder({required this.order, required this.warnings});

  final ShopOrder order;
  final List<String> warnings;
}
