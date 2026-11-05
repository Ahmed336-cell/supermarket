import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

const kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:4000',
);

class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  String? token;
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final hadToken = token != null;
    final encoded = body == null ? null : jsonEncode(body);

    late http.Response response;
    try {
      final future = switch (method) {
        'GET' => http.get(uri, headers: _headers),
        'POST' => http.post(uri, headers: _headers, body: encoded),
        'PUT' => http.put(uri, headers: _headers, body: encoded),
        'DELETE' => http.delete(uri, headers: _headers),
        _ => throw ApiException('Unsupported method $method'),
      };
      response = await future.timeout(const Duration(seconds: 20));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Cannot reach the API at $baseUrl. Start the backend, then try again.',
      );
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 400) {
        _maybeUnauthorized(response.statusCode, hadToken);
        throw ApiException('Request failed', status: response.statusCode);
      }
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 400) {
        _maybeUnauthorized(response.statusCode, hadToken);
        throw ApiException(response.body, status: response.statusCode);
      }
      return response.body;
    }

    if (response.statusCode >= 400) {
      _maybeUnauthorized(response.statusCode, hadToken);
      var message = 'Request failed';
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
        if (decoded['field'] != null) {
          message = '$message (${decoded['field']})';
        }
      }
      throw ApiException(message, status: response.statusCode);
    }
    return decoded;
  }

  void _maybeUnauthorized(int status, bool hadToken) {
    if (status == 401 && hadToken) onUnauthorized?.call();
  }

  Map<String, dynamic> _map(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<User> login(String email, String password) async {
    final data = _map(
      await _send(
        'POST',
        '/api/auth/login',
        body: {'email': email, 'password': password},
      ),
    );
    token = data['token'] as String;
    return User.fromJson(_map(data['user']));
  }

  Future<User> me() async {
    final data = _map(await _send('GET', '/api/auth/me'));
    return User.fromJson(_map(data['user']));
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/api/auth/logout');
    } catch (_) {}
    token = null;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final data = _map(
      await _send(
        'POST',
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      ),
    );
    return User.fromJson(_map(data['user']));
  }

  Future<List<Category>> categories() async {
    final data = await _send('GET', '/api/categories');
    return (data as List).map((item) => Category.fromJson(_map(item))).toList();
  }

  Future<Category> createCategory(Object body) async {
    return Category.fromJson(_map(await _send('POST', '/api/categories', body: body)));
  }

  Future<Category> updateCategory(String id, Object body) async {
    return Category.fromJson(
      _map(await _send('PUT', '/api/categories/$id', body: body)),
    );
  }

  Future<void> deleteCategory(String id) async {
    await _send('DELETE', '/api/categories/$id');
  }

  Future<List<Supplier>> suppliers() async {
    final data = await _send('GET', '/api/suppliers');
    return (data as List).map((item) => Supplier.fromJson(_map(item))).toList();
  }

  Future<Supplier> createSupplier(Object body) async {
    return Supplier.fromJson(_map(await _send('POST', '/api/suppliers', body: body)));
  }

  Future<Supplier> updateSupplier(String id, Object body) async {
    return Supplier.fromJson(
      _map(await _send('PUT', '/api/suppliers/$id', body: body)),
    );
  }

  Future<void> deleteSupplier(String id) async {
    await _send('DELETE', '/api/suppliers/$id');
  }

  Future<ProductPage> products({
    String? q,
    String? category,
    bool? lowStock,
    int page = 1,
    int limit = 20,
  }) async {
    final data = _map(
      await _send(
        'GET',
        '/api/products',
        query: {
          'page': '$page',
          'limit': '$limit',
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (category != null && category.isNotEmpty) 'category': category,
          if (lowStock == true) 'lowStock': 'true',
        },
      ),
    );
    final items = (data['items'] as List? ?? [])
        .map((item) => Product.fromJson(_map(item)))
        .toList();
    return ProductPage(items: items, total: toInt(data['total']), page: page);
  }

  Future<Product> createProduct(Object body) async {
    return Product.fromJson(_map(await _send('POST', '/api/products', body: body)));
  }

  Future<Product> updateProduct(String id, Object body) async {
    return Product.fromJson(
      _map(await _send('PUT', '/api/products/$id', body: body)),
    );
  }

  Future<void> deleteProduct(String id) async {
    await _send('DELETE', '/api/products/$id');
  }

  Future<Product> restock(String id, int quantity) async {
    return Product.fromJson(
      _map(
        await _send(
          'POST',
          '/api/products/$id/restock',
          body: {'quantity': quantity},
        ),
      ),
    );
  }

  Future<List<ShopOrder>> orders() async {
    final data = await _send('GET', '/api/orders');
    return (data as List).map((item) => ShopOrder.fromJson(_map(item))).toList();
  }

  Future<PlacedOrder> createOrder({
    required List<Map<String, dynamic>> items,
    required double orderDiscountPercent,
  }) async {
    final data = _map(
      await _send(
        'POST',
        '/api/orders',
        body: {
          'items': items,
          'orderDiscountPercent': orderDiscountPercent,
        },
      ),
    );
    final warnings = (data['lowStockWarnings'] as List? ?? [])
        .map((item) => item.toString())
        .toList();
    return PlacedOrder(order: ShopOrder.fromJson(data), warnings: warnings);
  }

  Future<ShopOrder> updateOrder(String id, Object body) async {
    return ShopOrder.fromJson(
      _map(await _send('PUT', '/api/orders/$id', body: body)),
    );
  }

  Future<void> deleteOrder(String id) async {
    await _send('DELETE', '/api/orders/$id');
  }
}
