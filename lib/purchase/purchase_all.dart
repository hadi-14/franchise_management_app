import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Import this for kIsWeb and Platform checks
import 'dart:io' show Platform;

import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'add_purchase_order_page.dart';
import 'purchase_order_details_page.dart';

class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  _PurchaseOrdersPageState createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPurchaseOrders);
  }

  void _filterPurchaseOrders() {
    setState(() {}); // Trigger the UI to update with the search filter
  }

  Future<List<DocumentSnapshot>> _fetchPurchaseOrders(String franchiseID) async {
    Query query = _firestore.collection('purchase').doc(franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('OrderID', isGreaterThanOrEqualTo: _searchController.text)
          .where('OrderID', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  Future<void> _deletePurchaseOrder(BuildContext context, String id, String franchiseID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this purchase order?'),
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
        await _firestore.collection('purchase').doc(franchiseID).collection('list').doc(id).delete();
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
        title: Text('Purchase Orders', style: theme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPurchaseOrderPage()),
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
                future: _fetchPurchaseOrders(userState.franchiseID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No purchase orders found.'));
                  }

                  // Use a card-based layout for mobile devices and table for others
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
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('store').doc(userState.franchiseID).collection('list').doc(order['StoreID']).get(),
                  builder: (context, storeSnapshot) {
                    if (storeSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading store...');
                    }
                    if (storeSnapshot.hasError) {
                      return const Text('Error loading store');
                    }
                    final storeData = storeSnapshot.data?.data() as Map<String, dynamic>?;
                    return Text(
                      'Store: ${storeData?['Name'] ?? 'Unknown'}',
                      style: theme.bodyMedium,
                    );
                  },
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPurchaseOrderPage(purchaseOrderId: data[index].id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePurchaseOrder(context, data[index].id, userState.franchiseID),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PurchaseOrderDetailsPage(orderId: data[index].id),
                          ),
                        );
                      },
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
          DataColumn(label: Text('Store')),
          DataColumn(label: Text('State')),
          DataColumn(label: Text('Net Total')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((orderDoc) {
          final order = orderDoc.data() as Map<String, dynamic>;
          return DataRow(cells: [
            DataCell(Text(order['OrderID'].toString())),
            DataCell(
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('store').doc(userState.franchiseID).collection('list').doc(order['StoreID']).get(),
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...');
                  }
                  if (storeSnapshot.hasError) {
                    return const Text('Error');
                  }
                  final storeData = storeSnapshot.data?.data() as Map<String, dynamic>?;
                  return Text(storeData?['Name'] ?? 'Unknown');
                },
              ),
            ),
            DataCell(Text(order['State'].toString())),
            DataCell(Text('\$${order['NetTotal'].toString()}')),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPurchaseOrderPage(purchaseOrderId: orderDoc.id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePurchaseOrder(context, orderDoc.id, userState.franchiseID),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseOrderDetailsPage(orderId: orderDoc.id),
                        ),
                      );
                    },
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
