import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/auth.dart';
import 'package:shop/providers/cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  String authToken;
  String userId;

  Orders(this.authToken, this.userId);

  List<OrderItem> get orders {
    return [..._orders];
  }

  int get count {
    return _orders.length;
  }

  void setAuthData(Auth auth) {
    authToken = auth.token;
    userId = auth.userId;
  }

  Future<void> add(List<CartItem> cartProducts, double total) async {
    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken';
    final timeStamp = DateTime.now();

    final res = await http.post(
      url,
      body: json.encode({
        'amount': total,
        'dateTime': timeStamp.toIso8601String(),
        'products': cartProducts.map((cp) => cp.toMap()).toList(),
      }),
    );

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(res.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: timeStamp,
      ),
    );

    notifyListeners();
  }

  Future<void> fetchAndSet() async {
    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken';
    final res = await http.get(url);
    final List<OrderItem> orders = [];
    final data = json.decode(res.body) as Map<String, dynamic>;

    if (data == null) return;

    data.forEach((orderId, orderData) {
      orders.add(OrderItem(
        id: orderId,
        amount: orderData['amount'],
        products: (orderData['products'] as List<dynamic>)
            .map((item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ))
            .toList(),
        dateTime: DateTime.parse(orderData['dateTime']),
      ));
    });

    _orders = orders.reversed.toList();

    notifyListeners();
  }
}
