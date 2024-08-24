import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  List<Map<String, dynamic>> _cart = [];

  List<Map<String, dynamic>> get cart => _cart;

  void addToCart(Map<String, dynamic> product) {
    // Check if the product is already in the cart
    bool productExists = false;
    for (var item in _cart) {
      if (item['productID'] == product['productID']) {
        item['quantity'] += product['quantity']; // Update quantity
        productExists = true;
        break;
      }
    }
    if (!productExists) {
      _cart.add(product);
    }
    notifyListeners();
  }

  void updateProductQuantity(String productID, int quantity) {
    for (var product in _cart) {
      if (product['productID'] == productID) {
        product['quantity'] = quantity;
        break;
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productID) {
    _cart.removeWhere((product) => product['productID'] == productID);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
