import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class ProductsPage extends StatefulWidget {
  final String franchiseID;

  const ProductsPage({super.key, required this.franchiseID});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PagedDataTableController<String, DocumentSnapshot> _pagedDataTableController = PagedDataTableController();

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    _pagedDataTableController.refresh(); // Trigger the fetcher with new filter
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchProducts(int pageSize, SortModel? sortModel, FilterModel filterModel, String? pageToken) async {

    Query query = _firestore.collection('product').doc(widget.franchiseID).collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('productName', isGreaterThanOrEqualTo: _searchController.text)
          .where('productName', isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Apply category filter
    if (_selectedCategory != null) {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Apply pagination
    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore.collection('product').doc(widget.franchiseID).collection('list').doc(pageToken).get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken = snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
  }

  Future<List<String>> _fetchCategories() async {
    if (widget.franchiseID.isEmpty) {
      return [];
    }
    final snapshot = await _firestore.collection('product').doc(widget.franchiseID).collection('category').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
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
                  'Products',
                  style: theme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDetailsPage(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
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
            FutureBuilder<List<String>>(
              future: _fetchCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No categories available.');
                } else {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: DropdownButton<String>(
                      borderRadius: BorderRadius.circular(12.0),
                      value: _selectedCategory,
                      hint: const Text('Select Category'),
                      items: snapshot.data!
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _pagedDataTableController.refresh();
                        });
                      },
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .75,
                  child: PagedDataTable<String, DocumentSnapshot>(
                    controller: _pagedDataTableController,
                    fetcher: _fetchProducts,
                    columns: [
                      TableColumn(
                        title: const Text("ProductID"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['productID'].toString());
                        },
                        id: 'productID',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Name"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['productName']);
                        },
                        id: 'productName',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Price"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['price'].toString());
                        },
                        id: 'price',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Category"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['category']);
                        },
                        id: 'category',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Quantity"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['quantity'].toString());
                        },
                        id: 'quantity',
                        sortable: true,
                        size: const FractionalColumnSize(0.15),
                      ),
                      TableColumn(
                        title: const Text("Actions"),
                        cellBuilder: (context, item, index) {
                          return Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showProductDetailsPage(context, productDoc: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteProduct(context, item.id),
                              ),
                            ],
                          );
                        },
                        size: const FractionalColumnSize(0.15),
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

  void _showProductDetailsPage(BuildContext context, {DocumentSnapshot? productDoc}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(productDoc: productDoc),
      ),
    );
    _pagedDataTableController.refresh();
  }

  Future<void> _deleteProduct(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
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
        await _firestore.collection('product').doc(widget.franchiseID).collection('list').doc(id).delete();
        _pagedDataTableController.refresh(); // Refresh the table after deletion
      }
    }
  }
}

class ProductDetailsPage extends StatefulWidget {
  final DocumentSnapshot? productDoc;

  const ProductDetailsPage({super.key, this.productDoc});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.productDoc != null) {
      final data = widget.productDoc!.data() as Map<String, dynamic>;
      _productNameController.text = data['productName'];
      _priceController.text = data['price'].toString();
      _selectedCategory = data['category'];
    }
  }

  Future<void> _saveProduct(String franchiseID) async {
    if (widget.productDoc == null) {
      final productID = await _getNextProductID(franchiseID);
      await _firestore.collection('product').doc(franchiseID).collection('list').add({
        'productID': productID,
        'productName': _productNameController.text,
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
      });
    } else {
      await _firestore.collection('product').doc(franchiseID).collection('list').doc(widget.productDoc!.id).update({
        'productName': _productNameController.text,
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
      });
    }
    Navigator.pop(context);
  }

  Future<String> _getNextProductID(String franchiseID) async {
    final snapshot = await _firestore.collection('product').doc(franchiseID).collection('list').orderBy('productID', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final lastID = int.parse(snapshot.docs.first['productID']);
      return (lastID + 1).toString();
    }
    return '1';
  }

  Future<List<String>> _fetchCategories(String franchiseID) async {
    final snapshot = await _firestore.collection('product').doc(franchiseID).collection('category').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productDoc == null ? 'Add Product' : 'Edit Product', style: theme.headlineMedium),
        backgroundColor: theme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('Product Name', _productNameController, theme),
              _buildTextField('Price', _priceController, theme, isNumeric: true),
              const SizedBox(height: 16),
              FutureBuilder<List<String>>(
                future: _fetchCategories(userState.franchiseID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No categories available.');
                  } else {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: DropdownButton<String>(
                        borderRadius: BorderRadius.circular(12.0),
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        items: snapshot.data!
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _saveProduct(userState.franchiseID),
                child: Text(widget.productDoc == null ? 'Add Product' : 'Update Product'),
              ),
            ],
          ),
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
}
