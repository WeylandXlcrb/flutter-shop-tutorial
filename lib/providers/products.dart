import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop/models/http_exception.dart';
import 'package:shop/providers/auth.dart';

import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  // var _showFavoritesOnly = false;

  String authToken;
  String userId;

  Products(this.authToken, this.userId);

  void setAuthData(Auth auth) {
    authToken = auth.token;
    userId = auth.userId;
  }

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((p) => p.isFavorite).toList();
    // }

    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((p) => p.isFavorite).toList();
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }
  //
  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> add(Product product) async {
    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/products.json?auth=$authToken';

    final res = await http.post(
      url,
      body: json.encode({
        'title': product.title,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'description': product.description,
        'creatorId': userId,
      }),
    );

    _items.add(Product(
      id: json.decode(res.body)['name'],
      title: product.title,
      imageUrl: product.imageUrl,
      price: product.price,
      description: product.description,
    ));

    notifyListeners();
  }

  Future<void> update(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);

    if (prodIndex < 0) return;

    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';

    await http.patch(
      url,
      body: json.encode({
        'title': newProduct.title,
        'imageUrl': newProduct.imageUrl,
        'price': newProduct.price,
        'description': newProduct.description,
      }),
    );

    _items[prodIndex] = newProduct;

    notifyListeners();
  }

  Product findById(String id) {
    return _items.firstWhere((p) => p.id == id);
  }

  Future<void> deleteOne(String id) async {
    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    final productIndex = _items.indexWhere((prod) => prod.id == id);
    var product = _items[productIndex];

    _items.removeAt(productIndex);
    notifyListeners();

    final res = await http.delete(url);

    if (res.statusCode >= 400) {
      _items.insert(productIndex, product);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }

    product = null;
  }

  Future<void> fetchAndSet([bool filterByUser = false]) async {
    final filters = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    final url =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filters';

    final res = await http.get(url);
    final data = json.decode(res.body) as Map<String, dynamic>;
    final List<Product> products = [];

    if (data == null) return;

    final favoritesUrl =
        'https://flutter-shop-aa8e5-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
    final favoritesRes = await http.get(favoritesUrl);
    final favoriteData = json.decode(favoritesRes.body);

    data.forEach((prodId, prodData) {
      products.add(
        Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite:
              favoriteData != null ? favoriteData[prodId] ?? false : false,
        ),
      );
    });

    _items = products;

    notifyListeners();
  }
}
