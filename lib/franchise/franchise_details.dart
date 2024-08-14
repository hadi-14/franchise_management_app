import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' show Platform;
import '../Common/flutter_flow_theme.dart';

class FranchisePage extends StatefulWidget {
  final String franchiseID;

  const FranchisePage({super.key, required this.franchiseID});

  @override
  _FranchisePageState createState() => _FranchisePageState();
}

class _FranchisePageState extends State<FranchisePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    setState(() {}); // Trigger the UI to update with the search filter
  }

  Future<List<DocumentSnapshot>> _fetchFranchises() async {
    Query query = _firestore.collection('franchise').doc(widget.franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('Name', isGreaterThanOrEqualTo: _searchController.text)
          .where('Name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  Future<void> _addFranchise() async {
    final user = _auth.currentUser;
    if (user != null) {
      final franchiseID = await _getNextFranchiseID(user.uid);
      await _firestore.collection('franchise').doc(widget.franchiseID).collection('list').add({
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
      setState(() {}); // Refresh the UI after adding the franchise
    }
  }

  Future<String> _getNextFranchiseID(String userId) async {
    final snapshot = await _firestore.collection('franchise').doc(userId).collection('list').orderBy('FranchiseID', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final lastID = int.parse(snapshot.docs.first['FranchiseID']);
      return (lastID + 1).toString();
    }
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Check if the current platform is Android, iOS, or Web
    final bool isMobile = Platform.isAndroid || Platform.isIOS || kIsWeb;

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
              child: FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchFranchises(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No franchises found.'));
                  }

                  return isMobile
                      ? _buildCardLayout(data, theme)
                      : _buildTableLayout(data, theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final franchise = data[index].data() as Map<String, dynamic>;
        final address = franchise['Address'] as Map<String, dynamic>;

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
                  'Franchise Name: ${franchise['Name']}',
                  style: theme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${franchise['Email']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${franchise['Phone']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}, ${address['zip']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditFranchiseModal(context, data[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFranchise(context, data[index].id),
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

  Widget _buildTableLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('FranchiseID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((franchiseDoc) {
          final franchise = franchiseDoc.data() as Map<String, dynamic>;
          final address = franchise['Address'] as Map<String, dynamic>;

          return DataRow(
            cells: [
              DataCell(Text(franchise['FranchiseID'].toString())),
              DataCell(Text(franchise['Name'])),
              DataCell(Text(franchise['Email'])),
              DataCell(Text(franchise['Phone'])),
              DataCell(Text('${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}, ${address['zip']}')),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditFranchiseModal(context, franchiseDoc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFranchise(context, franchiseDoc.id),
                    ),
                  ],
                ),
              ),
            ],
          );
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

  void _showAddFranchiseModal() {
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
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('City', _cityController, theme),
              _buildTextField('State', _stateController, theme),
              _buildTextField('Country', _countryController, theme),
              _buildTextField('Street', _streetController, theme),
              _buildTextField('Zip', _zipController, theme, isNumeric: true),
              ElevatedButton(
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(const Size(400, 50)),
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                style: ButtonStyle(
                  fixedSize: MaterialStateProperty.all(const Size(400, 50)),
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
      await _firestore.collection('franchise').doc(widget.franchiseID).collection('list').doc(id).update({
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
      setState(() {}); // Refresh the UI after updating the franchise
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
      if (widget.franchiseID.isNotEmpty) {
        await _firestore.collection('franchise').doc(widget.franchiseID).collection('list').doc(id).delete();
        setState(() {}); // Refresh the UI after deletion
      }
    }
  }
}
