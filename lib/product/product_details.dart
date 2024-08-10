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
  final PagedDataTableController<String, DocumentSnapshot>
  _pagedDataTableController = PagedDataTableController();

  String? _selectedCategoryID;
  Map<String, String> _categories = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _fetchCategories();
  }

  void _filterProducts() {
    _pagedDataTableController.refresh();
  }

  Future<void> _fetchCategories() async {
    if (widget.franchiseID.isEmpty) return;

    final snapshot = await _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('category')
        .get();

    setState(() {
      _categories = {
        for (var doc in snapshot.docs) doc.id: doc['name'] as String,
      };
    });
  }

  Future<(List<DocumentSnapshot>, String?)> _fetchProducts(int pageSize,
      SortModel? sortModel, FilterModel filterModel, String? pageToken) async {
    Query query = _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('productName', isGreaterThanOrEqualTo: _searchController.text)
          .where('productName',
          isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Apply category filter
    if (_selectedCategoryID != null) {
      query = query.where('categoryID', isEqualTo: _selectedCategoryID);
    }

    // Apply pagination
    if (pageToken != null) {
      query = query.startAfterDocument(await _firestore
          .collection('product')
          .doc(widget.franchiseID)
          .collection('list')
          .doc(pageToken)
          .get());
    }

    final snapshot = await query.limit(pageSize).get();
    final nextPageToken =
    snapshot.docs.isNotEmpty ? snapshot.docs.last.id : null;

    return (snapshot.docs, nextPageToken);
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
            if (_categories.isNotEmpty)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: DropdownButton<String>(
                  borderRadius: BorderRadius.circular(12.0),
                  value: _selectedCategoryID,
                  hint: const Text('Select Category'),
                  items: _categories.entries
                      .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryID = value;
                      _pagedDataTableController.refresh();
                    });
                  },
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
                        title: const Text("UPC Code"),
                        cellBuilder: (context, item, index) {
                          final data = item.data() as Map<String, dynamic>;
                          return Text(data['upcCode']);
                        },
                        id: 'upcCode',
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
                          final categoryName =
                              _categories[data['categoryID']] ?? 'Unknown';
                          return Text(categoryName);
                        },
                        id: 'categoryID',
                        sortable: true,
                        size: const FractionalColumnSize(0.1),
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
                                onPressed: () => _showProductDetailsPage(
                                    context,
                                    productDoc: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteProduct(context, item.id),
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

  void _showProductDetailsPage(BuildContext context,
      {DocumentSnapshot? productDoc}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productDoc: productDoc,
          categories: _categories,
          franchiseID: widget.franchiseID,
        ),
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
        await _firestore
            .collection('product')
            .doc(widget.franchiseID)
            .collection('list')
            .doc(id)
            .delete();
        _pagedDataTableController.refresh(); // Refresh the table after deletion
      }
    }
  }
}

class ProductDetailsPage extends StatefulWidget {
  final DocumentSnapshot? productDoc;
  final Map<String, String> categories;
  final String franchiseID;

  const ProductDetailsPage(
      {super.key, this.productDoc, required this.categories, required this.franchiseID});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _upcCodeController = TextEditingController();
  String? _selectedCategoryID;

  @override
  void initState() {
    super.initState();
    if (widget.productDoc != null) {
      final data = widget.productDoc!.data() as Map<String, dynamic>;
      _productNameController.text = data['productName'];
      _priceController.text = data['price'].toString();
      _quantityController.text = data['quantity'].toString();
      _upcCodeController.text = data['upcCode'].toString();
      _selectedCategoryID = data['categoryID'];
    }
  }

  Future<void> _saveProduct() async {
    final productData = {
      'productName': _productNameController.text,
      'price': double.parse(_priceController.text),
      'quantity': int.parse(_quantityController.text),
      'upcCode': _upcCodeController.text,
      'categoryID': _selectedCategoryID,
    };

    if (widget.productDoc == null) {
      final productID = await _getNextProductID();
      await _firestore
          .collection('product')
          .doc(widget.franchiseID)
          .collection('list')
          .add({
        'productID': productID,
        ...productData,
      });
    } else {
      await _firestore
          .collection('product')
          .doc(widget.franchiseID)
          .collection('list')
          .doc(widget.productDoc!.id)
          .update(productData);
    }
    Navigator.pop(context);
  }

  Future<String> _getNextProductID() async {
    final snapshot = await _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('list')
        .orderBy('productID', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final lastID = int.parse(snapshot.docs.first['productID']);
      return (lastID + 1).toString();
    }
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productDoc == null ? 'Add Product' : 'Edit Product',
            style: theme.headlineMedium),
        backgroundColor: theme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField('Product Name', _productNameController, theme),
              _buildTextField('Price', _priceController, theme,
                  isNumeric: true),
              _buildTextField('Quantity', _quantityController, theme,
                  isNumeric: true),
              _buildTextField('UPC Code', _upcCodeController, theme),
              const SizedBox(height: 16),
              DropdownButton<String>(
                borderRadius: BorderRadius.circular(12.0),
                value: _selectedCategoryID,
                hint: const Text('Select Category'),
                items: widget.categories.entries
                    .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryID = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.productDoc == null
                    ? 'Add Product'
                    : 'Update Product'),
              ),
            ],
          ),
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
}
