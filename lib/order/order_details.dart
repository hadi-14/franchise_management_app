import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/user_state.dart';

class OrderDetails extends StatelessWidget {
  final String orderId;

  const OrderDetails({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchOrderDetails(UserState userState) async {
    final orderSnapshot = await FirebaseFirestore.instance
        .collection('sales')
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
    final orderSnapshot = await FirebaseFirestore.instance
        .collection('sales')
        .doc(userState.franchiseID)
        .collection('list')
        .where('OrderID', isEqualTo: int.parse(orderId))
        .get();

    if (orderSnapshot.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('sales')
          .doc(userState.franchiseID)
          .collection('list')
          .doc(orderSnapshot.docs.first.id)
          .update({'State': newState});
      
      // Reload the previous page
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
      body: FutureBuilder<Map<String, dynamic>>(
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
          final String storeName = orderData['StoreID'];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Order ID', orderId, screenWidth),
                      const SizedBox(height: 15),
                      _buildDetailRow('State', state, screenWidth),
                      const SizedBox(height: 15),
                      _buildProductList(userState, productList, screenWidth),
                      const SizedBox(height: 15),
                      _buildDetailRow(
                          'Total Amount', '\$$totalAmount', screenWidth),
                      const SizedBox(height: 15),
                      _buildDetailRow('Store', storeName, screenWidth),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: _buildBottomButtons(orderData, userState, state, context),
              ),
            ],
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
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
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
                          Text(
                            productName,
                            style: const TextStyle(
                              color: Color(0xFF353934),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
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
                            product['isBox'] ? 'Box' : 'Piece',
                            style: const TextStyle(
                              color: Color(0xFF552E05),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${product['Quantity']} ${product['isBox'] ? 'Box(es)' : 'Piece(s)'}',
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

  Widget _buildBottomButtons(
      Map<String, dynamic> orderData, UserState userState, String state, BuildContext context) {
    return Row(
      children: [
        if (state == 'Pending') ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateOrderState(orderData, userState, 'Cancelled', context);
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
                _updateOrderState(orderData, userState, 'Approved', context);
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
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final nextState = _getNextState(state);
                _updateOrderState(orderData, userState, nextState, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD09A6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Mark as ${_getNextState(state)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }

  String _getNextState(String currentState) {
    switch (currentState) {
      case 'Pending':
        return 'Packed';
      case 'Packed':
        return 'Shipped';
      case 'Shipped':
        return 'Delivered';
      default:
        return 'Completed';
    }
  }
}
