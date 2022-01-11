import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem({
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    return _items.values.fold(0.0, (total, cartItem) {
      return total + cartItem.price * cartItem.quantity;
    });
  }

  List<CartItem> get itemList {
    return _items.values.toList();
  }

  void add(String productId, double price, String title) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (oldCartItem) => CartItem(
          id: oldCartItem.id,
          title: oldCartItem.title,
          quantity: oldCartItem.quantity + 1,
          price: oldCartItem.price,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          title: title,
          quantity: 1,
          price: price,
        ),
      );
    }
    notifyListeners();
  }

  remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  removeOne(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId].quantity > 1) {
      _items.update(
        productId,
        (oldCartItem) => CartItem(
          id: oldCartItem.id,
          title: oldCartItem.title,
          quantity: oldCartItem.quantity - 1,
          price: oldCartItem.price,
        ),
      );
    } else {
      _items.remove(productId);
    }

    notifyListeners();
  }

  clear() {
    _items.clear();
    notifyListeners();
  }
}
