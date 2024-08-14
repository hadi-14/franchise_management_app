import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // For kIsWeb

class StoreDetailsPage extends StatefulWidget {
  const StoreDetailsPage({super.key});

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    setState(() {}); // Trigger the UI to update with the search filter
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

  Future<List<DocumentSnapshot>> _fetchStores(String franchiseID) async {
    Query query = _firestore.collection('store').doc(franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('Name', isGreaterThanOrEqualTo: _searchController.text)
          .where('Name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    return snapshot.docs;
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
      setState(() {}); // Refresh the UI after adding
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

    // Check if the current platform is Android, iOS, or Web
    final bool isMobile = Platform.isAndroid || Platform.isIOS || kIsWeb;

    return Scaffold(
      appBar: AppBar(
        title: Text('Stores', style: theme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddStoreModal(userState.franchiseID),
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
                future: _fetchStores(userState.franchiseID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No stores found.'));
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
        final store = data[index].data() as Map<String, dynamic>;
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
                  'Store ID: ${store['StoreID']}',
                  style: theme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Name: ${store['Name']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Franchise: ${store['Franchise']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${store['Email']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${store['Phone']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Region: ${store['Region']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditStoreModal(context, data[index], userState.franchiseID),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteStore(context, data[index].id, userState.franchiseID),
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
          DataColumn(label: Text('Store ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Franchise')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Region')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((storeDoc) {
          final store = storeDoc.data() as Map<String, dynamic>;
          return DataRow(cells: [
            DataCell(Text(store['StoreID'].toString())),
            DataCell(Text(store['Name'])),
            DataCell(Text(store['Franchise'])),
            DataCell(Text(store['Email'])),
            DataCell(Text(store['Phone'])),
            DataCell(Text(store['Region'])),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditStoreModal(context, storeDoc, userState.franchiseID),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteStore(context, storeDoc.id, userState.franchiseID),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
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
      setState(() {}); // Refresh the UI after updating
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
        setState(() {}); // Refresh the UI after deletion
      }
    }
  }
}
