import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class StoreDetailsPage extends StatefulWidget {
  const StoreDetailsPage({super.key});

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PagedDataTableController<String, DocumentSnapshot> _pagedDataTableController = PagedDataTableController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  String? _selectedFranchise;
  List<String> _franchises = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStores);
    _fetchFranchises();
  }

  void _filterStores() {
    _pagedDataTableController.refresh(); // Trigger the fetcher with new filter
  }

  Future<void> _fetchFranchises() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore.collection('franchise').doc(user.uid).collection('list').get();
      setState(() {
        _franchises = snapshot.docs.map((doc) => doc['Name'] as String).toList();
      });
    }
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchStores(int pageSize, SortModel? sortModel, FilterModel filterModel, String? pageToken, String franchiseID) async {

    Query query = _firestore.collection('store').doc(franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('Name', isGreaterThanOrEqualTo: _searchController.text)
          .where('Name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Apply pagination
    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore.collection('store').doc(franchiseID).collection('list').doc(pageToken).get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken = snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
  }

  Future<void> _addStore(String franchiseID) async {
    final user = _auth.currentUser;
    if (user != null) {
      final storeID = await _getNextStoreID(franchiseID);
      await _firestore.collection('store').doc(franchiseID).collection('list').add({
        'StoreID': storeID,
        'Name': _nameController.text,
        'Franchise': _selectedFranchise,
        'Email': _emailController.text,
        'Phone': _phoneController.text,
        'Region': _regionController.text,
      });
      _pagedDataTableController.refresh(); // Refresh the table after adding
    }
  }

  Future<String> _getNextStoreID(String franchiseID) async {
    final snapshot = await _firestore.collection('store').doc(franchiseID).collection('list').orderBy('StoreID', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final lastID = int.parse(snapshot.docs.first['StoreID']);
      return (lastID + 1).toString();
    }
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stores',
                  style: theme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddStoreModal(userState.franchiseID),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.primaryBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    fetcher: (pageSize, sortModel, filterModel, pageToken) => _fetchStores(pageSize, sortModel, filterModel, pageToken, userState.franchiseID),
                    columns: [
                      TableColumn(
                        title: const Text("StoreID"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['StoreID'].toString());
                        },
                        id: 'StoreID',
                        sortable: true,
                        size: const FractionalColumnSize(0.1),
                      ),
                      TableColumn(
                        title: const Text("Name"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Name']);
                        },
                        id: 'Name',
                        sortable: true,
                        size: const FractionalColumnSize(0.1),
                      ),
                      TableColumn(
                        title: const Text("Franchise"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Franchise']);
                        },
                        id: 'Franchise',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Email"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Email']);
                        },
                        id: 'Email',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Phone"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Phone']);
                        },
                        id: 'Phone',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Region"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Region']);
                        },
                        id: 'Region',
                        size: const FractionalColumnSize(0.2),
                      ),
                      TableColumn(
                        title: const Text("Actions"),
                        cellBuilder: (context, item, index) {
                          return Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditStoreModal(context, item, userState.franchiseID),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteStore(context, item.id, userState.franchiseID),
                              ),
                            ],
                          );
                        },
                        size: const FractionalColumnSize(0.1),
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

  Widget _buildTextField(String label, TextEditingController controller, FlutterFlowTheme theme, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.labelLarge,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.alternate, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.primary, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        style: theme.bodyLarge,
      ),
    );
  }

  void _showAddStoreModal(String franchiseID) {
    final theme = FlutterFlowTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', _nameController, theme),
              _buildDropdown('Franchise', theme),
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('Region', _regionController, theme),
              ElevatedButton(
                onPressed: () {
                  _addStore(franchiseID);
                  Navigator.pop(context);
                },
                child: const Text('Add Store'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStoreModal(BuildContext context, DocumentSnapshot doc, String franchiseID) {
    final data = doc.data() as Map<String, dynamic>;
    final theme = FlutterFlowTheme.of(context);

    _nameController.text = data['Name'];
    _selectedFranchise = data['Franchise'];
    _emailController.text = data['Email'];
    _phoneController.text = data['Phone'];
    _regionController.text = data['Region'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', _nameController, theme),
              _buildDropdown('Franchise', theme),
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('Region', _regionController, theme),
              ElevatedButton(
                onPressed: () {
                  _updateStore(doc.id, franchiseID);
                  Navigator.pop(context);
                },
                child: const Text('Update Store'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedFranchise,
        items: _franchises.map((franchise) {
          return DropdownMenuItem<String>(
            value: franchise,
            child: Text(franchise),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedFranchise = value;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.labelLarge,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.alternate, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.primary, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        style: theme.bodyLarge,
      ),
    );
  }

  Future<void> _updateStore(String id, String franchiseID) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('store').doc(franchiseID).collection('list').doc(id).update({
        'Name': _nameController.text,
        'Franchise': _selectedFranchise,
        'Email': _emailController.text,
        'Phone': _phoneController.text,
        'Region': _regionController.text,
      });
      _pagedDataTableController.refresh(); // Refresh the table after updating
    }
  }

  Future<void> _deleteStore(BuildContext context, String id, String franchiseID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this store?'),
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
        await _firestore.collection('store').doc(franchiseID).collection('list').doc(id).delete();
        _pagedDataTableController.refresh(); // Refresh the table after deletion
      }
    }
  }
}
