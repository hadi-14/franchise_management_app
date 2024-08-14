import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'add_sales_order_page.dart';
import 'sales_order_details_page.dart';

class SalesOrdersPage extends StatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  _SalesOrdersPageState createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends State<SalesOrdersPage> {
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

  Future<List<DocumentSnapshot>> _fetchSalesOrders(String franchiseID) async {
    Query query =
    _firestore.collection('sales').doc(franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('OrderID', isGreaterThanOrEqualTo: _searchController.text)
          .where('OrderID',
          isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  Future<void> _deleteSalesOrder(
      BuildContext context, String id, String franchiseID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this sales order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (franchiseID.isNotEmpty) {
        await _firestore
            .collection('sales')
            .doc(franchiseID)
            .collection('list')
            .doc(id)
            .delete();
        setState(() {}); // Refresh the UI after deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    // Check if the current platform is Android, iOS, or Web
    final bool isMobile = Platform.isAndroid || Platform.isIOS || kIsWeb;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            userState.role == 'franchisee' ? 'Purchase Orders' : 'Sales Orders',
            style: theme.headlineMedium),
        actions: [
          if (userState.role == 'owner' || userState.role == 'franchisee')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddSalesOrderPage()),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchSalesOrders(userState.franchiseID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No sales orders found.'));
                  }

                  return isMobile
                      ? _buildCardLayout(data, theme, userState)
                      : _buildTableLayout(data, theme, userState);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme, UserState userState) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index].data() as Map<String, dynamic>;
        final createdBy = order['createdBy'];
        final user = userState.userName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: ${order['OrderID']}',
                  style: theme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'State: ${order['State']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Net Total: \$${order['NetTotal'].toString()}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Created By: ${order['createdBy']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (userState.role == 'owner' ||
                        (userState.role == 'franchisee' &&
                            user == createdBy))
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddSalesOrderPage(
                                  salesOrderId: data[index].id),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.print_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SalesOrderDetailsPage(orderId: data[index].id),
                          ),
                        );
                      },
                    ),
                    if (userState.role == 'owner' ||
                        (userState.role == 'franchisee' && user == createdBy))
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteSalesOrder(
                            context, data[index].id, userState.franchiseID),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme, UserState userState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('State')),
          DataColumn(label: Text('Net Total')),
          DataColumn(label: Text('Created By')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((orderDoc) {
          final order = orderDoc.data() as Map<String, dynamic>;
          final createdBy = order['createdBy'];
          final user = userState.userName;

          return DataRow(cells: [
            DataCell(Text(order['OrderID'].toString())),
            DataCell(Text(order['State'])),
            DataCell(Text(order['NetTotal'].toString())),
            DataCell(Text(order['createdBy'].toString())),
            DataCell(
              Row(
                children: [
                  if (userState.role == 'owner' ||
                      (userState.role == 'franchisee' && user == createdBy))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddSalesOrderPage(
                                salesOrderId: orderDoc.id),
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SalesOrderDetailsPage(orderId: orderDoc.id),
                        ),
                      );
                    },
                  ),
                  if (userState.role == 'owner' ||
                      (userState.role == 'franchisee' && user == createdBy))
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSalesOrder(
                          context, orderDoc.id, userState.franchiseID),
                    ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
