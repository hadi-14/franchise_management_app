import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paged_datatable/paged_datatable.dart';
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
  final PagedDataTableController<String, DocumentSnapshot> _pagedDataTableController = PagedDataTableController();

  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCategories);
  }

  void _filterCategories() {
    _pagedDataTableController.refresh();
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchCategories(int pageSize, SortModel? sortModel, FilterModel filterModel, String? pageToken) async {
    Query query = _firestore.collection('product').doc(widget.franchiseID).collection('category');

    if (_searchController.text.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchController.text)
          .where('name', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore.collection('product').doc(widget.franchiseID).collection('category').doc(pageToken).get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken = snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
  }

  Future<void> _addCategory() async {
    if (widget.franchiseID.isEmpty) return;

    await _firestore.collection('product').doc(widget.franchiseID).collection('category').add({
      'name': _nameController.text,
    });
    _pagedDataTableController.refresh();
  }

  Future<void> _deleteCategories() async {
    if (widget.franchiseID.isEmpty || _selectedCategories.isEmpty) return;

    final batch = _firestore.batch();
    for (final categoryId in _selectedCategories) {
      batch.delete(_firestore.collection('product').doc(widget.franchiseID).collection('category').doc(categoryId));
    }
    await batch.commit();
    setState(() {
      _selectedCategories.clear();
    });
    _pagedDataTableController.refresh();
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .75,
                  child: PagedDataTable<String, DocumentSnapshot>(
                    controller: _pagedDataTableController,
                    fetcher: _fetchCategories,
                    columns: [
                      TableColumn(
                        title: const Text("Select"),
                        cellBuilder: (context, item, index) {
                          return Checkbox(
                            value: _selectedCategories.contains(item.id),
                            onChanged: (selected) {
                              setState(() {
                                if (selected!) {
                                  _selectedCategories.add(item.id);
                                } else {
                                  _selectedCategories.remove(item.id);
                                }
                              });
                            },
                          );
                        },
                        size: const FractionalColumnSize(0.1),
                      ),
                      TableColumn(
                        title: const Text("Name"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['name']);
                        },
                        id: 'Name',
                        sortable: true,
                        size: const FractionalColumnSize(0.9),
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

  Widget _buildTextField(String label, TextEditingController controller, FlutterFlowTheme theme) {
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
}
