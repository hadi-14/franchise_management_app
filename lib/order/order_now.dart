import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../Common/drawer.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import '../product/product_detail_view.dart';

class OrderNowFranchisePage extends StatefulWidget {
  final String franchiseID;

  const OrderNowFranchisePage({super.key, required this.franchiseID});

  @override
  _OrderNowFranchisePageState createState() => _OrderNowFranchisePageState();
}

class _OrderNowFranchisePageState extends State<OrderNowFranchisePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategoryID;
  Map<String, String> _categories = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(() {
      setState(() {}); // Update the UI when the search text changes
    });
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
    final userState = Provider.of<UserState>(context);

    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = Platform.isAndroid || Platform.isIOS || kIsWeb;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: screenWidth * 0.6,
              height: 30,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0x70D1A784)),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 7.0, top: 5.0),
                child: Text(
                  'Franchise ID: ${userState.franchiseInternalID}',
                  style: const TextStyle(
                    color: Color(0xFF552E05),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.06),
            SizedBox(
              width: 30,
              height: 30,
              child: Image.network(userState.profilePhoto),
            ),
          ],
        ),
      ),
      drawer: DrawerWidget(), // Drawer added here
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 20.0,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
            ),
            child: Container(
              width: screenWidth * 0.9,
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x26686868),
                    blurRadius: 8,
                    offset: Offset(0, 1),
                    spreadRadius: 3,
                  )
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: Icon(Icons.search),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF552E05),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 20.0,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              child: DropdownButton<String>(
                value: _selectedCategoryID,
                hint: const Text('Select Category'),
                isExpanded: true,
                borderRadius: BorderRadius.circular(12.0),
                items: _categories.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryID = value;
                  });
                },
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                  return const Center(child: CircularProgressIndicator());
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
    );
  }

  Widget _buildCardLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600
            ? 3
            : 2, // Adjusts the number of columns based on screen width
        crossAxisSpacing: 10,
        mainAxisSpacing: 2,
        childAspectRatio: MediaQuery.of(context).size.width > 600
            ? 0.8
            : 0.7, // Adjusts the aspect ratio based on screen width
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final product = data[index].data() as Map<String, dynamic>;
        product['ID'] = data[index].id;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product)),
            );
          },
          child: SizedBox(
            width: 250,
            height: 181,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Image.network(
                    width: 250,
                    height: 135,
                    product['image'] ?? "https://via.placeholder.com/250x135",
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 135,
                  child: Container(
                    width: 250,
                    height: 66,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['productName'],
                          style: theme.bodyLarge,
                        ),
                        Text(
                          '\$ ${product['price']}',
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableLayout(
      List<DocumentSnapshot> data, FlutterFlowTheme theme) {
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
                    onPressed: () => _showProductDetailsPopup(context,
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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  child: Text(
                      productDoc == null ? 'Add Product' : 'Update Product'),
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
