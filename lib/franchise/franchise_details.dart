import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paged_datatable/paged_datatable.dart';
import '../Common/flutter_flow_theme.dart';

class FranchisePage extends StatefulWidget {
  const FranchisePage({super.key});

  @override
  _FranchisePageState createState() => _FranchisePageState();
}

class _FranchisePageState extends State<FranchisePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PagedDataTableController<String, DocumentSnapshot>
      _pagedDataTableController = PagedDataTableController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFranchises);
  }

  void _filterFranchises() {
    _pagedDataTableController.refresh(); // Trigger the fetcher with new filter
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchFranchises(int pageSize,
      SortModel? sortModel, FilterModel filterModel, String? pageToken) async {
    final user = _auth.currentUser!;
    Query query =
        _firestore.collection('franchise').doc(user.uid).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('Name', isGreaterThanOrEqualTo: _searchController.text)
          .where('Name',
              isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Apply sorting
    if (sortModel != null) {
      // for (final sortColumn in sortModel.columns) {
      // query = query.orderBy(SortModel.fieldName, descending: SortModel.descending);
      // }
    }

    // Apply pagination
    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore
          .collection('franchise')
          .doc(user.uid)
          .collection('list')
          .doc(pageToken)
          .get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken =
        snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
  }

  Future<void> _addFranchise() async {
    final user = _auth.currentUser;
    if (user != null) {
      final franchiseID = await _getNextFranchiseID(user.uid);
      await _firestore
          .collection('franchise')
          .doc(user.uid)
          .collection('list')
          .add({
        'FranchiseID': franchiseID,
        'Name': _nameController.text,
        'Email': _emailController.text,
        'Phone': _phoneController.text,
        'Address': {
          'city': _cityController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'street': _streetController.text,
          'zip': int.parse(_zipController.text),
        },
      });
      _pagedDataTableController.refresh(); // Refresh the table after adding
    }
  }

  Future<String> _getNextFranchiseID(String userId) async {
    final snapshot = await _firestore
        .collection('franchise')
        .doc(userId)
        .collection('list')
        .orderBy('FranchiseID', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final lastID = int.parse(snapshot.docs.first['FranchiseID']);
      return (lastID + 1).toString();
    }
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Franchises',
                  style: theme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddFranchiseModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Franchise'),
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
                    fetcher: _fetchFranchises,
                    columns: [
                      TableColumn(
                        title: const Text("FranchiseID"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['FranchiseID'].toString());
                        },
                        id: 'FranchiseID',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Name"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['Name']);
                        },
                        id: 'Name',
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
                        title: const Text("Address"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          final address =
                              data['Address'] as Map<String, dynamic>;
                          return Text(
                              '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}, ${address['zip']}');
                        },
                        id: 'Address',
                        size: const FractionalColumnSize(0.3),
                      ),
                      TableColumn(
                        title: const Text("Actions"),
                        cellBuilder: (context, item, index) {
                          return Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditFranchiseModal(context, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteFranchise(context, item.id),
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

  Widget _buildTextField(
      String label, TextEditingController controller, FlutterFlowTheme theme,
      {bool isNumeric = false}) {
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

  void _showAddFranchiseModal() {
    final theme = FlutterFlowTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', _nameController, theme),
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('City', _cityController, theme),
              _buildTextField('State', _stateController, theme),
              _buildTextField('Country', _countryController, theme),
              _buildTextField('Street', _streetController, theme),
              _buildTextField('Zip', _zipController, theme, isNumeric: true),
              ElevatedButton(                
                style: const ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(Size(400, 50)),
                ),
                onPressed: () {
                  _addFranchise();
                  Navigator.pop(context);
                },
                child: const Text('Add Franchise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFranchiseModal(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final address = data['Address'] as Map<String, dynamic>;
    final theme = FlutterFlowTheme.of(context);

    _nameController.text = data['Name'];
    _emailController.text = data['Email'];
    _phoneController.text = data['Phone'];
    _cityController.text = address['city'];
    _stateController.text = address['state'];
    _countryController.text = address['country'];
    _streetController.text = address['street'];
    _zipController.text = address['zip'].toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', _nameController, theme),
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('City', _cityController, theme),
              _buildTextField('State', _stateController, theme),
              _buildTextField('Country', _countryController, theme),
              _buildTextField('Street', _streetController, theme),
              _buildTextField('Zip', _zipController, theme, isNumeric: true),
              ElevatedButton(
                style: const ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(Size(400, 50)),
                ),
                onPressed: () {
                  _updateFranchise(doc.id);
                  Navigator.pop(context);
                },
                child: const Text('Update Franchise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateFranchise(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('franchise')
          .doc(user.uid)
          .collection('list')
          .doc(id)
          .update({
        'Name': _nameController.text,
        'Email': _emailController.text,
        'Phone': _phoneController.text,
        'Address': {
          'city': _cityController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'street': _streetController.text,
          'zip': int.parse(_zipController.text),
        },
      });
      _pagedDataTableController.refresh(); // Refresh the table after updating
    }
  }

  Future<void> _deleteFranchise(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this franchise?'),
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
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('franchise')
            .doc(user.uid)
            .collection('list')
            .doc(id)
            .delete();

        _pagedDataTableController.refresh(); // Refresh the table after deletion
      }
    }
  }
}
