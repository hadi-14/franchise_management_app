import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../AppState.dart';
import '../Common/user_state.dart';

class CheckoutCart extends StatelessWidget {
  final TabController tabController;
  const CheckoutCart({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final appState = Provider.of<AppState>(context);
    final cartItems = appState.cart;

    return Scaffold(
      appBar: AppBar(toolbarOpacity: 0,
        title: const Center(
          child: Text(
            'Checkout',
            style: TextStyle(
              color: Color(0xFF353934),
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            color: Color(0xFF353934),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        InkWell(
                          child: const Text(
                            '+ Add Items',
                            style: TextStyle(
                              color: Color(0xFFD09A6C),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            tabController.animateTo(0);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.025,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: cartItems.map((product) {
                            return CartItem(
                              product: product,
                              onRemove: () =>
                                  appState.removeFromCart(product['productID']),
                              onAddQuantity: () =>
                                  appState.updateProductQuantity(
                                      product['productID'],
                                      product['quantity'] + 1),
                              onReduceQuantity: () {
                                if (product['quantity'] > 1) {
                                  appState.updateProductQuantity(
                                      product['productID'],
                                      product['quantity'] - 1);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomSection(context, cartItems, userState, appState),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
      BuildContext context,
      List<Map<String, dynamic>> cartItems,
      UserState userState,
      AppState appState) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.05,
          10.0, MediaQuery.of(context).size.width * 0.05, 75.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Subtotal',
            '\$${(_calculateSubtotal(cartItems)).toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Service Charges (1%)',
            '+\$${(_calculateSubtotal(cartItems) * 0.01).toStringAsFixed(2)}',
          ),
          const Divider(height: 2.0),
          _buildSummaryRow(
            'Total Payment',
            '\$${(_calculateSubtotal(cartItems) + _calculateSubtotal(cartItems) * 0.01).toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              await _processOrder(context, userState, cartItems, appState);
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 56,
              decoration: ShapeDecoration(
                color: const Color(0xFFD09A6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  'Order Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  double _calculateSubtotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(
        0, (total, item) => total + item['price'] * item['quantity']);
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isTotal ? const Color(0xFF353934) : const Color(0xFF8E918D),
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  isTotal ? const Color(0xFFD09A6C) : const Color(0xFF353934),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder(BuildContext context, UserState userState,
      List<Map<String, dynamic>> cartItems, dynamic appState) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String franchiseID = userState.franchiseID;
    final String createdBy = userState.userName;

    double subtotal = _calculateSubtotal(cartItems);
    double serviceFee = subtotal * 0.01;
    double totalAmount = subtotal + serviceFee;

    // Create an order ID (example: incrementing an integer)
    final snapshot = await _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .orderBy('OrderID', descending: true)
        .limit(1)
        .get();

    int nextOrderID = snapshot.docs.isNotEmpty
        ? (snapshot.docs.first.data()['OrderID'] as int) + 1
        : 1;

    // Create the order data
    final orderData = {
      'OrderID': nextOrderID,
      'Date': Timestamp.now(),
      'NetTotal': subtotal,
      'ServiceFee': serviceFee,
      'State': 'Pending',
      'StoreID': userState.franchiseInternalID,
      'Tax': 0, // Assuming tax is 0, adjust as needed
      'TotalAmount': totalAmount,
      'createdBy': createdBy,
      'items': cartItems.map((item) {
        return {
          'Category': item['categoryID'],
          'Product': item['productID'],
          'Quantity': item['quantity'],
          'Total': item['quantity'] * item['price'],
          'UnitPrice': item['price'],
          'isBox': item['isBox'] ?? false,
          'piecesPerBox': item['piecesPerBox'] ?? 0,
        };
      }).toList(),
    };

    // Save the order data to Firestore
    await _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .add(orderData);

    // Clear the cart after saving the order
    appState.clearCart();

    // Show confirmation or navigate to another screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order has been placed successfully!'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class CartItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemove;
  final VoidCallback onAddQuantity;
  final VoidCallback onReduceQuantity;

  const CartItem({
    super.key,
    required this.product,
    required this.onRemove,
    required this.onAddQuantity,
    required this.onReduceQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 138,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 138,
              height: 138,
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    product['image'] ?? "https://via.placeholder.com/138x138",
                  ),
                  fit: BoxFit.fill,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            left: 138,
            top: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 138,
              decoration: const ShapeDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 11,
                    top: 18,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Text(
                        product['productName'],
                        style: const TextStyle(
                          color: Color(0xFF353934),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 11,
                    top: 103,
                    child: SizedBox(
                      width: 42,
                      child: Text(
                        '\$${product['price']}',
                        style: const TextStyle(
                          color: Color(0xFF353934),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 10,
                    child: IconButton(
                      icon: Image.asset(
                        'assets/Icons/trash.png',
                        width: 20,
                        height: 20,
                      ),
                      onPressed: onRemove,
                    ),
                  ),
                  Positioned(
                    right: 15,
                    top: 106,
                    child: SizedBox(
                      width: 88,
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFF552E05)),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(2)),
                              shape: BoxShape.rectangle,
                            ),
                            child: IconButton(
                              padding: const EdgeInsets.all(0),
                              icon: const Icon(Icons.remove, size: 14),
                              color: const Color(0xFF552E05),
                              onPressed: onReduceQuantity,
                            ),
                          ),
                          Text(
                            '${product['quantity']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0A0D14),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: Color(0xFF552E05),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2)),
                              shape: BoxShape.rectangle,
                            ),
                            child: IconButton(
                              padding: const EdgeInsets.all(0),
                              icon: const Icon(Icons.add, size: 14),
                              color: Colors.white,
                              onPressed: onAddQuantity,
                            ),
                          ),
                        ],
                      ),
                    ),
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
