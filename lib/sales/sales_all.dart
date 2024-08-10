import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
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
  final PagedDataTableController<String, DocumentSnapshot>
      _pagedDataTableController = PagedDataTableController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSalesOrders);
  }

  void _filterSalesOrders() {
    _pagedDataTableController.refresh(); // Trigger the fetcher with new filter
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchSalesOrders(
      int pageSize,
      SortModel? sortModel,
      FilterModel filterModel,
      String? pageToken,
      String franchiseID) async {
    Query query =
        _firestore.collection('sales').doc(franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('OrderID', isGreaterThanOrEqualTo: _searchController.text)
          .where('OrderID',
              isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Apply pagination
    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore
          .collection('sales')
          .doc(franchiseID)
          .collection('list')
          .doc(pageToken)
          .get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken =
        snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
  }

  Future<void> _deleteSalesOrder(
      BuildContext context, String id, String franchiseID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this sales order?'),
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
        _pagedDataTableController.refresh(); // Refresh the table after deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .75,
                  child: PagedDataTable<String, DocumentSnapshot>(
                    controller: _pagedDataTableController,
                    fetcher: (pageSize, sortModel, filterModel, pageToken) =>
                        _fetchSalesOrders(pageSize, sortModel, filterModel,
                            pageToken, userState.franchiseID),
                    columns: [
                      TableColumn(
                        title: const Text("OrderID"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['OrderID'].toString());
                        },
                        id: 'OrderID',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("State"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['State']);
                        },
                        id: 'State',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Net Total"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['NetTotal'].toString());
                        },
                        id: 'NetTotal',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Created By"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['createdBy'].toString());
                        },
                        id: 'CreatedBy',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Actions"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          final createdBy = data['createdBy'];
                          final user = userState.userName;

                          return Row(
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
                                            salesOrderId: item.id),
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
                                          SalesOrderDetailsPage(
                                              orderId: item.id),
                                    ),
                                  );
                                },
                              ),
                              if (userState.role == 'owner' ||
                                  (userState.role == 'franchisee' &&
                                      user == createdBy))
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSalesOrder(
                                      context, item.id, userState.franchiseID),
                                ),
                            ],
                          );
                        },
                        size: const FractionalColumnSize(0.2),
                      ),
                    ],
                    initialPageSize: 10,
                    pageSizes: const [5, 10, 20, 50],
                    configuration: const PagedDataTableConfiguration(
                      copyItems: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
