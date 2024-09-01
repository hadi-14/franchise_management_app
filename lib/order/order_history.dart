import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSalesOrders);
  }

  void _filterSalesOrders() {
    setState(() {}); // Trigger the UI to update with the search filter
  }

  Future<List<Map<String, dynamic>>> _fetchSalesOrdersWithAddress(
      String franchiseID) async {
    Query query = _firestore
        .collection('sales')
        .doc(franchiseID)
        .collection('list')
        .where('State', whereIn: ['Completed', 'Canceled']);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('OrderID', isGreaterThanOrEqualTo: _searchController.text)
          .where('OrderID',
              isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    List<Map<String, dynamic>> ordersWithAddresses = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
      String storeID = orderData['StoreID'];

      // Fetch the address from the user collection
      final address = await _fetchFranchiseAddress(storeID);
      orderData['address'] = address; // Add address to the order data
      ordersWithAddresses.add(orderData);
    }

    return ordersWithAddresses;
  }

  Future<Map<String, dynamic>> _fetchFranchiseAddress(
      String franchiseID) async {
    final snapshot = await _firestore
        .collection('user')
        .where('franchiseInternalID', isEqualTo: franchiseID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['Address']!;
    } else {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);
    final bool isOwnerOrStaff =
        userState.role == 'owner' || userState.role == 'staff';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Color(0xFF353934),
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: isOwnerOrStaff
            ? _buildOwnerOrderHistoryView()
            : _buildFranchiseeOrderHistoryView(),
      ),
    );
  }

  Widget _buildFranchiseeOrderHistoryView() {
    final userState = Provider.of<UserState>(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSalesOrdersWithAddress(userState.franchiseID),
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
              final isCompleted = order['State'] == 'Completed';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 158,
                              child: Text(
                                'Order Id : ${order['OrderID']}',
                                style: const TextStyle(
                                  color: Color(0xFF353934),
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '\$${order['NetTotal']}',
                              style: TextStyle(
                                color: isCompleted
                                    ? const Color(0xFFD09A6C)
                                    : const Color(0xFFFF0F0F),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery To: ${userState.franchiseInternalID}',
                              style: const TextStyle(
                                color: Color(0xFF8E918D),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              isCompleted ? 'Completed' : 'Canceled',
                              style: TextStyle(
                                color: isCompleted
                                    ? const Color(0xFFD09A6C)
                                    : const Color(0xFFFF0F0F),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${order['address']['street']}, ${order['address']['city']}, ${order['address']['state']}, ${order['address']['country']}, ${order['address']['zip']}',
                        style: const TextStyle(
                          color: Color(0xFF8E918D),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Widget _buildOwnerOrderHistoryView() {
    final userState = Provider.of<UserState>(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSalesOrdersWithAddress(userState.franchiseID),
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 75.0),
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final order = data[index];
              final isCompleted = order['State'] == 'Completed';
              final DateTime date = (order['Date'] as Timestamp).toDate();
              final String formattedDate =
                  DateFormat('yyyy-MM-dd').format(date);

              return Container(
                width: 336,
                height: 162,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Id: ${order['OrderID']}',
                          style: const TextStyle(
                            color: Color(0xFF353934),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF8E918D),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Franchise Code: ${order['StoreID']}',
                      style: const TextStyle(
                        color: Color(0xFF552E05),
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Delivered to: ${order['address']['street']}, ${order['address']['city']}, ${order['address']['state']}, ${order['address']['country']}, ${order['address']['zip']}',
                      style: const TextStyle(
                        color: Color(0xFF8E918D),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${order['NetTotal']}',
                          style: const TextStyle(
                            color: Color(0xFFD09A6C),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isCompleted ? 'Completed' : 'Canceled',
                          style: TextStyle(
                            color: isCompleted
                                ? const Color(0xFFD09A6C)
                                : const Color(0xFFFF0F0F),
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
            },
          ),
        );
      },
    );
  }
}
