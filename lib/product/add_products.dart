import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'dart:io';

class AddProducts extends StatefulWidget {
  final Map<String, dynamic>? productData; // Optional product data for editing

  const AddProducts({super.key, this.productData});

  @override
  _AddProductsState createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _productNameController = TextEditingController();
  final _productDescController = TextEditingController();
  final _skuController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _taxController = TextEditingController();
  final _quantityController = TextEditingController();
  final _itemsInBoxController = TextEditingController();

  bool isPieceSelected = false;
  bool isBoxSelected = false;
  File? _selectedImage;
  String? _imageUrl;
  String? selectedCategory;
  String? productId; // Hold the product ID for editing

  List<DropdownMenuItem<String>> _categoryDropdownItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    // If productData is provided, populate the fields
    if (widget.productData != null) {
      _productNameController.text = widget.productData!['productName'] ?? '';
      _productDescController.text = widget.productData!['desc'] ?? '';
      _skuController.text = widget.productData!['upcCode'] ?? '';
      _totalAmountController.text =
          (widget.productData!['price'] ?? '').toString();
      _taxController.text = (widget.productData!['tax'] ?? '').toString();
      _quantityController.text =
          (widget.productData!['quantity'] ?? '').toString();
      _itemsInBoxController.text =
          (widget.productData!['itemsInBox'] ?? '').toString();
      if (widget.productData!.containsKey('type')) {
        isPieceSelected = widget.productData!['type']['piece'] ?? false;
        isBoxSelected = widget.productData!['type']['box'] ?? false;
      }
      selectedCategory = widget.productData!['categoryID'] ?? null;
      _imageUrl = widget.productData!['image'] ?? null;
      productId = widget.productData!['ID']; // Set the product ID for updating
    }
  }

  Future<void> _fetchCategories() async {
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    if (franchiseID.isNotEmpty) {
      final categoriesSnapshot = await _firestore
          .collection('product')
          .doc(franchiseID)
          .collection('category')
          .get();

      setState(() {
        _categoryDropdownItems = categoriesSnapshot.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc.data()['name']),
                ))
            .toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      final fileName = _selectedImage!.path.split('/').last;
      final ref = _storage.ref().child('product_images/$fileName');
      await ref.putFile(_selectedImage!);
      _imageUrl = await ref.getDownloadURL();
    }
  }

  Future<void> _loadImageFromFirebase() async {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      try {
        final ref = _storage.refFromURL(_imageUrl!);
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrl = url;
        });
      } catch (e) {
        print('Failed to load image from Firebase Storage: $e');
        _imageUrl = null;
      }
    }
  }

  Future<void> _saveProduct() async {
    // Ensure all required fields are filled out
    if (_productNameController.text.isEmpty ||
        _productDescController.text.isEmpty ||
        _skuController.text.isEmpty ||
        _totalAmountController.text.isEmpty ||
        selectedCategory == null ||
        (_selectedImage == null && _imageUrl == null)) {
      // Show a snackbar to notify the user that all fields must be filled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please fill out all required fields and add an image.'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit the method if validation fails
    }

    // Continue with the product saving process
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    await _uploadImage();

    if (_imageUrl != null) {
      final productData = {
        'categoryID': selectedCategory,
        'desc': _productDescController.text,
        'image': _imageUrl,
        'price': double.tryParse(_totalAmountController.text) ?? 0.0,
        'tax': double.tryParse(_taxController.text) ?? 0.0,
        'upcCode': _skuController.text,
        'productName': _productNameController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'itemsInBox': int.tryParse(_itemsInBoxController.text) ?? 0,
        'type': {
          'piece': isPieceSelected,
          'box': isBoxSelected,
        },
      };

      if (productId != null) {
        // Update the existing product
        await _firestore
            .collection('product')
            .doc(franchiseID)
            .collection('list')
            .doc(productId)
            .update(productData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product has been updated'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Add a new product
        await _firestore
            .collection('product')
            .doc(franchiseID)
            .collection('list')
            .add(productData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product has been added'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Reset the form after submission
      // _resetForm();

      Navigator.of(context).pop();
    }
  }

  void _resetForm() {
    _productNameController.clear();
    _productDescController.clear();
    _skuController.clear();
    _totalAmountController.clear();
    _taxController.clear();
    _quantityController.clear();
    _itemsInBoxController.clear();
    setState(() {
      isPieceSelected = false;
      isBoxSelected = false;
      selectedCategory = null;
      _selectedImage = null;
      _imageUrl = null;
      productId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Load image from Firebase if necessary
    if (_imageUrl != null && _selectedImage == null) {
      _loadImageFromFirebase();
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.productData != null ? 'Edit Product' : 'Add Product',
          style: theme.headlineSmall.override(
            color: theme.secondaryText,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: theme.secondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                label: 'Product Name',
                hint: 'Enter product name',
                theme: theme,
                controller: _productNameController,
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                label: 'Product Description',
                hint: 'Enter product description',
                theme: theme,
                lines: 3,
                controller: _productDescController,
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildImagePicker(theme),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                label: 'SKU',
                hint: 'Enter SKU',
                theme: theme,
                controller: _skuController,
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Price',
                      hint: 'Enter amount (Item)',
                      theme: theme,
                      keyboardType: TextInputType.number,
                      controller: _totalAmountController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: 'Tax %',
                      hint: 'Enter tax percentage',
                      theme: theme,
                      keyboardType: TextInputType.number,
                      controller: _taxController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildDropdownField(
                label: 'Category',
                hint: 'Select category',
                theme: theme,
                items: _categoryDropdownItems,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                value: selectedCategory,
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildTypeSelection(theme),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                label: 'Stock',
                hint: 'Enter stock (Item)',
                theme: theme,
                keyboardType: TextInputType.number,
                controller: _quantityController,
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildInputField(
                label: 'Items in Box',
                hint: 'Enter number of items in box',
                theme: theme,
                keyboardType: TextInputType.number,
                controller: _itemsInBoxController,
                enabled: isBoxSelected,
              ),
              SizedBox(height: screenHeight * 0.05),
              _buildActionButton(
                label: (widget.productData != null)
                    ? 'Update Product'
                    : 'Add Product',
                color: theme.primary,
                textColor: theme.tertiary,
                theme: theme,
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(FlutterFlowTheme theme) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: screenWidth,
              height: 79,
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFFD09A6C)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: 322,
                      height: 79,
                      fit: BoxFit.cover,
                    )
                  : _imageUrl != null
                      ? Image.network(
                          _imageUrl!,
                          width: 322,
                          height: 79,
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
          ),
          if (_selectedImage == null && _imageUrl == null)
            Container(
              width: 322,
              height: 79,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 154,
                    height: 32,
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 43,
                          top: 7,
                          child: Text(
                            'Click to upload',
                            style: TextStyle(
                              color: Color(0xFFD09A6C),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            child: const Icon(
                              Icons.upload_file,
                              color: Color(0xFFD09A6C),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required FlutterFlowTheme theme,
    int lines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.headlineSmall.override(
            color: theme.primaryText,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.bodyMedium.override(
              color: theme.secondaryText,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: theme.tertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.alternate),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: theme.bodyMedium.override(
            color: theme.secondaryText,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required FlutterFlowTheme theme,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    double? width,
    String? value, // Add a value parameter to show the selected value
  }) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width

    return SizedBox(
      width: width ??
          screenWidth, // Use provided width or screen width as the default
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.headlineSmall.override(
              color: theme.primaryText,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.bodyMedium.override(
                color: theme.secondaryText,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: theme.tertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.alternate),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.alternate, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: theme.tertiary,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: isPieceSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isPieceSelected = value ?? false;
                    });
                  },
                  activeColor: theme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Item',
                  style: theme.bodyMedium.override(
                    color: theme.primaryText,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.alternate, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: theme.tertiary,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: isBoxSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isBoxSelected = value ?? false;
                    });
                  },
                  activeColor: theme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Box',
                  style: theme.bodyMedium.override(
                    color: theme.primaryText,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required FlutterFlowTheme theme,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: theme.bodyMedium.override(
            color: textColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
