import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Common/user_state.dart';

class AppState extends ChangeNotifier {
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _inventory = []; // Define an inventory list

  List<Map<String, dynamic>> get cart => _cart;
  List<Map<String, dynamic>> get inventory =>
      _inventory; // Getter for inventory

  void addToCart(Map<String, dynamic> product) {
    // Check if the product is already in the cart
    bool productExists = false;
    for (var item in _cart) {
      if (item['productName'] == product['productName']) {
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

  Future<void> addToInventory(
      BuildContext context, Map<String, dynamic> product) async {
    final userState = Provider.of<UserState>(context, listen: false);

    // Convert the quantity based on whether it's a box or piece
    int quantityToAdd = product['quantity'];

    // Get the reference to the product document in Firestore
    final productDocRef = FirebaseFirestore.instance
        .collection('product') // Assuming your inventory is in this collection
        .doc(userState.franchiseID)
        .collection('list');

    try {
      // Find the document with the matching product ID and product name
      final querySnapshot = await productDocRef
          .where('upcCode', isEqualTo: product['upcCode'])
          .where('productName', isEqualTo: product['productName'])
          .limit(1)
          .get();

      print(product);

      if (querySnapshot.docs.isNotEmpty) {
        // If the product exists, update its quantity
        final docRef = querySnapshot.docs.first.reference;
        final currentQuantity = querySnapshot.docs.first.data()['quantity'];
        int newQuantity = currentQuantity + quantityToAdd;

        await docRef.update({'quantity': newQuantity});
      } else {
        // Log or handle the case where the product was not found (though you mentioned it's guaranteed to be there)
        print("Product not found in inventory.");
      }
    } catch (e) {
      print("Failed to update inventory: $e");
    }
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
}
