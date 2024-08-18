import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' show Platform;
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

  String? _selectedCategoryID;
  Map<String, String> _categories = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _fetchCategories();
  }

  void _filterProducts() {
    setState(() {}); // Trigger the UI to update with the search filter
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

  Future<List<DocumentSnapshot>> _fetchProducts() async {
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

    final snapshot = await query.get();
    return snapshot.docs;
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
                  'Products',
                  style: theme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDetailsPopup(context),
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
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('No products found.'));
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
        final product = data[index].data() as Map<String, dynamic>;
        final categoryName = _categories[product['categoryID']] ?? 'Unknown';

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
                  'Product ID: ${product['productID']}',
                  style: theme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Name: ${product['productName']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'UPC Code: ${product['upcCode']}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: \$${product['price'].toString()}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: $categoryName',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quantity: ${product['quantity'].toString()}',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showProductDetailsPopup(
                          context,
                          productDoc: data[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          _deleteProduct(context, data[index].id),
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
          DataColumn(label: Text('Product ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('UPC Code')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((productDoc) {
          final product = productDoc.data() as Map<String, dynamic>;
          final categoryName = _categories[product['categoryID']] ?? 'Unknown';

          return DataRow(cells: [
            DataCell(Text(product['productID'].toString())),
            DataCell(Text(product['productName'])),
            DataCell(Text(product['upcCode'])),
            DataCell(Text(product['price'].toString())),
            DataCell(Text(categoryName)),
            DataCell(Text(product['quantity'].toString())),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showProductDetailsPopup(
                        context,
                        productDoc: productDoc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProduct(context, productDoc.id),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  void _showProductDetailsPopup(BuildContext context,
      {DocumentSnapshot? productDoc}) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController upcCodeController = TextEditingController();
    String? selectedCategoryID;

    final theme = FlutterFlowTheme.of(context);

    if (productDoc != null) {
      final data = productDoc.data() as Map<String, dynamic>;
      productNameController.text = data['productName'];
      priceController.text = data['price'].toString();
      quantityController.text = data['quantity'].toString();
      upcCodeController.text = data['upcCode'].toString();
      selectedCategoryID = data['categoryID'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Product Name', productNameController, theme),
                _buildTextField('Price', priceController, theme,
                    isNumeric: true),
                _buildTextField('Quantity', quantityController, theme,
                    isNumeric: true),
                _buildTextField('UPC Code', upcCodeController, theme),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  borderRadius: BorderRadius.circular(12.0),
                  value: selectedCategoryID,
                  hint: const Text('Select Category'),
                  items: _categories.entries
                      .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryID = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final productData = {
                      'productName': productNameController.text,
                      'price': double.parse(priceController.text),
                      'quantity': int.parse(quantityController.text),
                      'upcCode': upcCodeController.text,
                      'categoryID': selectedCategoryID,
                    };

                    if (productDoc == null) {
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
                          .doc(productDoc.id)
                          .update(productData);
                    }
                    Navigator.pop(context);
                    setState(() {}); // Refresh the UI
                  },
                  child: Text(productDoc == null
                      ? 'Add Product'
                      : 'Update Product'),
                ),
              ],
            ),
          ),
        );
      },
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
        setState(() {}); // Refresh the UI after deletion
      }
    }
  }
}
