import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/user_state.dart';

class OrderDetails extends StatelessWidget {
  final String orderId;
  final bool isPurchaseOrder;

  const OrderDetails({
    Key? key,
    required this.orderId,
    this.isPurchaseOrder = false,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchOrderDetails(UserState userState) async {
    final collection = isPurchaseOrder ? 'purchase' : 'sales';
    final orderSnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .doc(userState.franchiseID)
        .collection('list')
        .where('OrderID', isEqualTo: int.parse(orderId))
        .get();

    if (orderSnapshot.docs.isNotEmpty) {
      return orderSnapshot.docs.first.data();
    } else {
      throw Exception('Order not found');
    }
  }

  Future<String> _fetchProductName(
      UserState userState, String productId) async {
    final productSnapshot = await FirebaseFirestore.instance
        .collection('product')
        .doc(userState.franchiseID)
        .collection('list')
        .doc(productId)
        .get();

    if (productSnapshot.exists) {
      return productSnapshot.data()?['productName'] ?? 'Unknown Product';
    } else {
      return 'Unknown Product';
    }
  }

  Future<void> _updateOrderState(Map<String, dynamic> orderData,
      UserState userState, String newState, BuildContext context) async {
    final collection = isPurchaseOrder ? 'purchase' : 'sales';
    final orderSnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .doc(userState.franchiseID)
        .collection('list')
        .where('OrderID', isEqualTo: int.parse(orderId))
        .get();

    if (orderSnapshot.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();

      if (newState == 'Approved' || newState == 'Shipped') {
        final List<dynamic> productList = orderData['items'];

        for (var product in productList) {
          final productRef = FirebaseFirestore.instance
              .collection('product')
              .doc(userState.franchiseID)
              .collection('list')
              .doc(product['Product']);

          final productSnapshot = await productRef.get();

          if (productSnapshot.exists) {
            final currentQuantity = productSnapshot.data()?['quantity'] ?? 0;
            final updatedQuantity = currentQuantity - product['Quantity'];

            batch.update(productRef, {'quantity': updatedQuantity});
          }
        }
      }

      batch.update(orderSnapshot.docs.first.reference, {'State': newState});

      await batch.commit();

      Navigator.pop(context, true);
    } else {
      throw Exception('Order not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchOrderDetails(userState),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Order not found'));
              }
          
              final orderData = snapshot.data!;
              final String state = orderData['State'];
              final List<dynamic> productList = orderData['items'];
              final double totalAmount = orderData['TotalAmount'];
              final String storeName = orderData['StoreID'] ?? '';
          
              return Stack(children: [
                Container(height: MediaQuery.of(context).size.height - 100,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Order ID', orderId, screenWidth),
                        const SizedBox(height: 15),
                        _buildDetailRow('State', state, screenWidth),
                        const SizedBox(height: 15),
                        _buildProductList(
                            userState, productList, screenWidth),
                        const SizedBox(height: 100), // Space for floating bar
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTotalAmountRow(
                            context, screenWidth, orderData),
                        const SizedBox(height: 10),
                        _buildBottomButtons(context, userState, orderId),
                      ],
                    ),
                  ),
                ),
              ]);
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }

  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E9ED), width: 1),
        color: const Color(0xFFFAFAFA),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF353934),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF8E918D),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildProductList(
      UserState userState, List<dynamic> productList, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product List',
          style: TextStyle(
            color: Color(0xFF353934),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ...productList.map((product) {
          return FutureBuilder<String>(
            future: _fetchProductName(userState, product['Product']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFE5E5EA), width: 1),
                    color: const Color(0xFFFAFAFA),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFE5E5EA), width: 1),
                    color: const Color(0xFFFAFAFA),
                  ),
                  child:
                      const Center(child: Text('Error loading product name')),
                );
              } else {
                final productName = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFE5E5EA), width: 1),
                    color: const Color(0xFFFAFAFA),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: const TextStyle(
                                color: Color(0xFF353934),
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${product['UnitPrice']}',
                            style: const TextStyle(
                              color: Color(0xFF8E918D),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product['isBox'] ? 'Box' : 'Item',
                            style: const TextStyle(
                              color: Color(0xFF552E05),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${product['Quantity']} ${product['isBox'] ? 'Box(es)' : 'Item(s)'}',
                            style: const TextStyle(
                              color: Color(0xFF8E918D),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalAmountRow(BuildContext context, double screenWidth,
      Map<String, dynamic> orderData) {
    final double totalAmount = double.parse(orderData['TotalAmount'].toStringAsFixed(2));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFD09A6C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '\$$totalAmount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, UserState userState, String orderId) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Call Cancel Order function
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E4E9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFD09A6C),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Call Approve Order function
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD09A6C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
