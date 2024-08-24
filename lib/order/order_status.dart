import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Common/drawer.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOrders);
  }

  void _filterOrders() {
    setState(() {}); // Trigger UI update
  }

  Future<List<Map<String, dynamic>>> _fetchOrders(String franchiseID) async {
    Query query = _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .where('State', isNotEqualTo: 'Completed');

    // Apply search filter
    if (_searchController.text.isNotEmpty &&
        int.tryParse(_searchController.text) != null) {
      query =
          query.where('OrderID', isEqualTo: int.parse(_searchController.text));
    }

    final snapshot = await query.get();

    List<Map<String, dynamic>> ordersWithImages = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
      List<String> productImages = [];

      List<dynamic> items = orderData['items'];
      for (var item in items.take(3)) {
        // Limit to 3 items
        final productID = item['Product'];
        final productSnapshot = await _firestore
            .collection('product')
            .doc(franchiseID)
            .collection('list')
            .doc(productID)
            .get();
        if (productSnapshot.exists) {
          productImages.add(productSnapshot.data()?['image'] ??
              'https://via.placeholder.com/98x60');
        }
      }

      orderData['productImages'] = productImages;
      ordersWithImages.add(orderData);
    }

    return ordersWithImages;
  }

  Future<void> _markAsCompleted(String franchiseID, String orderID) async {
    final data = await _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .where('OrderID', isEqualTo: int.parse(orderID))
        .get();

    await _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .doc(data.docs.first.id)
        .update({'State': 'Completed'});
    setState(() {}); // Refresh UI after update
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String franchiseID, String orderID) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
              'Are you sure you want to mark this order as completed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _markAsCompleted(franchiseID, orderID);
    }
  }

  Widget _buildImagePlaceholder(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 97.67,
      height: 60,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.fill,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildStatusChip(
      String label, Color bgColor, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Order Status',
          style: TextStyle(
            color: Color(0xFF353934),
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: SizedBox(
              width: 30,
              height: 30,
              child: Image.network(userState.profilePhoto),
            ),
          ),
        ],
      ),
      drawer: DrawerWidget(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 11.0, top: 36.0),
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x0A686868),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.search, color: Color(0xFF552E05)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF552E05),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchOrders(userState.franchiseID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final order = data[index];
                    final List<String> productImages = order['productImages'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Order Id : ${order['OrderID']}',
                            style: const TextStyle(
                              color: Color(0xFF353934),
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(
                                right: 9, bottom: 6, left: 9),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFAFAFA),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 15,
                                  offset: Offset(0, 10),
                                  spreadRadius: 0,
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: productImages.length,
                                    itemBuilder: (context, imageIndex) {
                                      return _buildImagePlaceholder(
                                          productImages[imageIndex]);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatusChip(
                                      order['State'],
                                      _getStatusColor(order['State']),
                                      _getStatusTextColor(order['State']),
                                      _getStatusBorderColor(order['State']),
                                    ),
                                    if (order['State'] == 'Shipped')
                                      TextButton(
                                        onPressed: () =>
                                            _showConfirmationDialog(
                                                context,
                                                userState.franchiseID,
                                                order['OrderID'].toString()),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                                width: 29,
                                                child: Image.asset(
                                                    'assets/Icons/mark.png')),
                                            const Text(
                                              'Mark as Complete',
                                              style: TextStyle(
                                                color: Color(0xFFD09A6C),
                                                fontSize: 10,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Franchise ID: ${userState.franchiseInternalID}',
                                        style: const TextStyle(
                                          color: Color(0xFF353934),
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${userState.address['street']}, ${userState.address['city']}, ${userState.address['state']}, ${userState.address['country']}, ${userState.address['zip']}',
                                        style: const TextStyle(
                                          color: Color(0xFF8E918D),
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '\$${order['NetTotal']}',
                                      style: const TextStyle(
                                        color: Color(0xFFD09A6C),
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String state) {
    switch (state) {
      case 'Pending':
        return Colors.white;
      case 'Packed':
        return const Color(0xFF85C2AA);
      case 'Shipped':
        return const Color(0xFFE0BAE8);
      default:
        return const Color.fromARGB(255, 148, 148, 148);
    }
  }

  Color _getStatusTextColor(String state) {
    switch (state) {
      case 'Pending':
        return const Color(0xFFB47E51);
      case 'Packed':
        return Colors.white;
      case 'Shipped':
        return const Color(0xFF8D5499);
      default:
        return const Color.fromARGB(255, 0, 0, 0);
    }
  }

  Color _getStatusBorderColor(String state) {
    switch (state) {
      case 'Pending':
        return const Color(0xFFDDBDA2);
      case 'Packed':
        return const Color(0xFFB1D1C4);
      case 'Shipped':
        return const Color(0xFFC99AD3);
      default:
        return const Color(0xFFE2E4E9);
    }
  }
}
