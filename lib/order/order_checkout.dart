import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../AppState.dart';
import '../Common/user_state.dart';

class CheckoutCart extends StatefulWidget {
  final TabController tabController;
  const CheckoutCart({super.key, required this.tabController});

  @override
  _CheckoutCartState createState() => _CheckoutCartState();
}

class _CheckoutCartState extends State<CheckoutCart> with SingleTickerProviderStateMixin {
  String? _selectedSupplierID; // Store the selected supplier locally
  Map<String, String> _suppliers = {}; // Supplier list

  @override
  void initState() {
    super.initState();
    if (_isAdminOrStaff()) {
      _fetchSuppliers(); // Fetch suppliers if admin or staff
    }
  }

  // Determine if the user is admin or staff
  bool _isAdminOrStaff() {
    final userState = Provider.of<UserState>(context, listen: false);
    return userState.role == 'admin' || userState.role == 'staff';
  }

  // Fetch suppliers from Firestore
  Future<void> _fetchSuppliers() async {
    final snapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    setState(() {
      _suppliers = {
        for (var doc in snapshot.docs) doc.id: doc['name'] as String,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final appState = Provider.of<AppState>(context);
    final cartItems = appState.cart;

    return DefaultTabController(
      length: _isAdminOrStaff() ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
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
          bottom: _isAdminOrStaff()
              ? const TabBar(
                  tabs: [
                    Tab(text: "Buyer View"),
                    Tab(text: "Seller View"),
                  ],
                )
              : null,
        ),
        body: TabBarView(
          children: [
            _buildCheckoutBody(context, cartItems, userState, appState),
            if (_isAdminOrStaff()) _buildSupplierSelection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBody(
    BuildContext context,
    List<Map<String, dynamic>> cartItems,
    UserState userState,
    AppState appState,
  ) {
    return Column(
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
                          widget.tabController.animateTo(0);
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
                            onAddQuantity: () => appState.updateProductQuantity(
                                product['productID'], product['quantity'] + 1),
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
    );
  }

  // Supplier Selection View
  Widget _buildSupplierSelection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Supplier',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: Color(0xFF353934),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedSupplierID,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            elevation: 16,
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                _selectedSupplierID = newValue;
              });
            },
            items: _suppliers.entries
                .map((entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            hint: const Text('Select a Supplier'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
      BuildContext context,
      List<Map<String, dynamic>> cartItems,
      UserState userState,
      AppState appState) {
    final subtotal = _calculateSubtotal(cartItems);
    final tax = _calculateTax(cartItems);
    final serviceFee = subtotal * 0.01;
    final total = subtotal + tax + serviceFee;

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
            '\$${subtotal.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Tax',
            '+\$${tax.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Service Charges (1%)',
            '+\$${serviceFee.toStringAsFixed(2)}',
          ),
          const Divider(height: 2.0),
          _buildSummaryRow(
            'Total Payment',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 10),
          _buildButtonsForCheckout(context, userState, cartItems, appState, total, tax, serviceFee),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

Widget _buildButtonsForCheckout(BuildContext context, UserState userState,
    List<Map<String, dynamic>> cartItems, AppState appState, double total, double tax, double serviceFee) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Expanded(
        child: InkWell(
          onTap: total > 0
              ? () async {
                  await _processOrder(context, userState, cartItems, appState,
                      tax, serviceFee, total);
                }
              : null,
          child: Container(
            height: 56,
            decoration: ShapeDecoration(
              color: total > 0 ? const Color(0xFF552E05) : Colors.grey,
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
      ),
      const SizedBox(width: 10),
      Expanded(
        child: InkWell(
          onTap: total > 0
              ? () async {
                  await _processPurchase(context, userState, cartItems, appState,
                      tax, serviceFee, total);
                }
              : null,
          child: Container(
            height: 56,
            decoration: ShapeDecoration(
              color: total > 0 ? const Color(0xFFD09A6C) : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Center(
              child: Text(
                'Purchase Now',
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
      ),
    ],
  );
}

  double _calculateSubtotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(
        0, (total, item) => total + item['price'] * item['quantity']);
  }

  double _calculateTax(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (total, item) {
      final taxPercentage = item['tax'] ?? 0.0;
      return total + (item['price'] * item['quantity'] * taxPercentage / 100);
    });
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

  Future<void> _processOrder(
      BuildContext context,
      UserState userState,
      List<Map<String, dynamic>> cartItems,
      AppState appState,
      double tax,
      double serviceFee,
      double totalAmount) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String franchiseID = userState.franchiseID;
    final String createdBy = userState.userName;

    // Create an order ID
    final snapshot = await _firestore
        .collection('orders')
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
      'NetTotal': _calculateSubtotal(cartItems),
      'Tax': tax,
      'ServiceFee': serviceFee,
      'State': 'Pending',
      'StoreID': userState.franchiseInternalID,
      'TotalAmount': totalAmount,
      'createdBy': createdBy,
      'items': cartItems.map((item) {
        return {
          'Category': item['categoryID'],
          'Product': item['productID'],
          'productName': item['productName'],
          'Quantity': item['quantity'],
          'Total': item['quantity'] * item['price'],
          'UnitPrice': item['price'],
          'isBox': item['type'] == 'Box',
          'piecesPerBox': item['piecesPerBox'] ?? 0,
        };
      }).toList(),
    };

    // Save the order data to Firestore
    await _firestore
        .collection('orders')
        .doc(franchiseID)
        .collection('list')
        .add(orderData);

    // Clear the cart after saving the order
    appState.clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order has been placed successfully!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _processPurchase(
      BuildContext context,
      UserState userState,
      List<Map<String, dynamic>> cartItems,
      AppState appState,
      double tax,
      double serviceFee,
      double totalAmount) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String franchiseID = userState.franchiseID;
    final String createdBy = userState.userName;

    // Create a purchase ID
    final snapshot = await _firestore
        .collection('purchase')
        .doc(franchiseID)
        .collection('list')
        .orderBy('OrderID', descending: true)
        .limit(1)
        .get();

    int nextPurchaseID = snapshot.docs.isNotEmpty
        ? (snapshot.docs.first.data()['OrderID'] as int) + 1
        : 1;

    // Create the purchase data
    final purchaseData = {
      'OrderID': nextPurchaseID,
      'Date': Timestamp.now(),
      'NetTotal': _calculateSubtotal(cartItems),
      'Tax': tax,
      'ServiceFee': serviceFee,
      'State': 'Pending',
      'StoreID': userState.franchiseInternalID,
      'TotalAmount': totalAmount,
      'createdBy': createdBy,
      'supplierID': cartItems.first['supplier'], // Add supplierID if admin or staff
      'items': cartItems.map((item) {
        return {
          'Category': item['categoryID'],
          'Product': item['productID'],
          'productName': item['productName'],
          'Quantity': item['quantity'],
          'Total': item['quantity'] * item['price'],
          'UnitPrice': item['price'],
          'isBox': item['type'] == 'Box',
          'piecesPerBox': item['piecesPerBox'] ?? 0,
        };
      }).toList(),
    };

    // Save the purchase data to Firestore
    await _firestore
        .collection('purchase')
        .doc(franchiseID)
        .collection('list')
        .add(purchaseData);

    // Clear the cart after saving the purchase
    appState.clearCart();

    // Show confirmation or navigate to another screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchase has been placed successfully!'),
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
                        maxLines: 3,
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
                      width: MediaQuery.of(context).size.width * 0.4,
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
