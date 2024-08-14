import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' show Platform;
import '../Common/flutter_flow_theme.dart';

class CategoriesPage extends StatefulWidget {
  final String franchiseID;

  const CategoriesPage({super.key, required this.franchiseID});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCategories);
  }

  void _filterCategories() {
    setState(() {}); // Trigger the UI to update with the search filter
  }

  Future<List<DocumentSnapshot>> _fetchCategories() async {
    Query query = _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('category');

    if (_searchController.text.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchController.text)
          .where('name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  Future<void> _addCategory() async {
    if (widget.franchiseID.isEmpty) return;

    await _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('category')
        .add({
      'name': _nameController.text,
    });
    setState(() {}); // Refresh the UI after adding the category
  }

  Future<void> _updateCategory(String id) async {
    if (widget.franchiseID.isEmpty || id.isEmpty) return;

    await _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('category')
        .doc(id)
        .update({
      'name': _nameController.text,
    });
    setState(() {}); // Refresh the UI after updating the category
  }

  Future<void> _deleteCategories() async {
    if (widget.franchiseID.isEmpty || _selectedCategories.isEmpty) return;

    final batch = _firestore.batch();
    for (final categoryId in _selectedCategories) {
      batch.delete(_firestore
          .collection('product')
          .doc(widget.franchiseID)
          .collection('category')
          .doc(categoryId));
    }
    await batch.commit();
    setState(() {
      _selectedCategories.clear();
    });
    setState(() {}); // Refresh the UI after deletion
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
                  'Categories',
                  style: theme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
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
            if (_selectedCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _deleteCategories,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete Selected'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No categories found.'));
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
        final category = data[index].data() as Map<String, dynamic>;

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
                  'Category Name: ${category['name']}',
                  style: theme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _selectedCategories.contains(data[index].id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            _selectedCategories.add(data[index].id);
                          } else {
                            _selectedCategories.remove(data[index].id);
                          }
                        });
                      },
                    ),
                    const Text('Select'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCategoryModal(
                          data[index].id, category['name']),
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
          DataColumn(label: Text('Select')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((categoryDoc) {
          final category = categoryDoc.data() as Map<String, dynamic>;

          return DataRow(
            selected: _selectedCategories.contains(categoryDoc.id),
            onSelectChanged: (selected) {
              setState(() {
                if (selected!) {
                  _selectedCategories.add(categoryDoc.id);
                } else {
                  _selectedCategories.remove(categoryDoc.id);
                }
              });
            },
            cells: [
              DataCell(
                Checkbox(
                  value: _selectedCategories.contains(categoryDoc.id),
                  onChanged: (selected) {
                    setState(() {
                      if (selected!) {
                        _selectedCategories.add(categoryDoc.id);
                      } else {
                        _selectedCategories.remove(categoryDoc.id);
                      }
                    });
                  },
                ),
              ),
              DataCell(Text(category['name'])),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCategoryModal(
                          categoryDoc.id, category['name']),
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

  Widget _buildTextField(
      String label, TextEditingController controller, FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
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

  void _showAddCategoryModal() {
    _nameController.clear();
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
              ElevatedButton(
                onPressed: () {
                  _addCategory();
                  Navigator.pop(context);
                },
                child: const Text('Add Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCategoryModal(String id, String currentName) {
    _nameController.text = currentName;
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
              ElevatedButton(
                onPressed: () {
                  _updateCategory(id);
                  Navigator.pop(context);
                },
                child: const Text('Update Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
