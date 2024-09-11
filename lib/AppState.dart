import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Common/user_state.dart';

class AppState extends ChangeNotifier {
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _inventory = []; // Inventory list
  String? _selectedSupplierID; // Store selected supplier

  List<Map<String, dynamic>> get cart => _cart;
  List<Map<String, dynamic>> get inventory => _inventory; // Getter for inventory
  String? get selectedSupplierID => _selectedSupplierID;

  // Set the selected supplier
  void setSelectedSupplier(String supplierID) {
    _selectedSupplierID = supplierID;
    notifyListeners();
  }

  // Add product to cart with supplierID
  void addToCart(Map<String, dynamic> product, String supplierID) {
    product['supplierID'] = supplierID; // Add supplier to product

    bool productExists = false;
    for (var item in _cart) {
      if (item['productName'] == product['productName'] && item['supplierID'] == supplierID) {
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

  void clearInventory() {
    _inventory.clear();
    notifyListeners();
  }

  // Calculation functions for subtotal, tax, service fee, and total
  double _calculateSubtotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (total, item) => total + item['price'] * item['quantity']);
  }

  double _calculateTax(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (total, item) {
      final taxPercentage = item['tax'] ?? 0.0;
      return total + (item['price'] * item['quantity'] * taxPercentage / 100);
    });
  }

  double _calculateServiceFee(List<Map<String, dynamic>> cartItems) {
    final subtotal = _calculateSubtotal(cartItems);
    return subtotal * 0.01; // 1% service fee
  }

  double _calculateTotal(List<Map<String, dynamic>> cartItems) {
    final subtotal = _calculateSubtotal(cartItems);
    final tax = _calculateTax(cartItems);
    final serviceFee = _calculateServiceFee(cartItems);
    return subtotal + tax + serviceFee;
  }
}
