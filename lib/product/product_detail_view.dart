import 'package:flutter/material.dart';
import 'package:franchise_management_app/AppState.dart';
import 'package:franchise_management_app/Common/flutter_flow_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../Common/user_state.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _pieceQuantity = 0;
  int _boxQuantity = 0;
  String? _imageUrl; // To store the fetched image URL from Firebase

  @override
  void initState() {
    super.initState();
    _loadImageFromFirebase();
  }

  Future<void> _loadImageFromFirebase() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.product['image']);
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url;
      });
    } catch (e) {
      print("Error loading image from Firebase: $e");
      setState(() {
        _imageUrl = "https://via.placeholder.com/150"; // Fallback placeholder image
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final appState = Provider.of<AppState>(context);
    final userState = Provider.of<UserState>(context, listen: false);

    final bool isPieceAvailable = widget.product['type']['piece'] ?? false;
    final bool isBoxAvailable = widget.product['type']['box'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Details",
          style: theme.displayMedium.copyWith(
            color: const Color(0xFF353934),
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 33),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 171,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_imageUrl ?? widget.product['image']),
                          fit: BoxFit.fitWidth,
                          onError: (_, __) {
                            _loadImageFromFirebase(); // Attempt to load image from Firebase if NetworkImage fails
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.product['productName'],
                      style: theme.displayMedium.copyWith(
                        color: const Color(0xFF353934),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.product['desc'],
                      softWrap: true,
                      maxLines: 10,
                      style: theme.bodySmall.copyWith(
                        color: const Color(0xFF8E918D),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomSection(context, appState, isPieceAvailable, isBoxAvailable),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, AppState appState,
      bool isPieceAvailable, bool isBoxAvailable) {
    final theme = FlutterFlowTheme.of(context);
    final bool canAddToCart = (_pieceQuantity > 0 && isPieceAvailable) ||
        (_boxQuantity > 0 && isBoxAvailable);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPieceAvailable) ...[
            _buildProductRow(
              theme,
              context,
              "Item",
              _pieceQuantity,
              (value) => setState(() => _pieceQuantity = value),
            ),
          ],
          if (isBoxAvailable) ...[
            const SizedBox(height: 20),
            _buildProductRow(
              theme,
              context,
              "Box",
              _boxQuantity,
              (value) => setState(() => _boxQuantity = value),
            ),
          ],
          const SizedBox(height: 20),
          if (isPieceAvailable || isBoxAvailable)
            Container(
              width: MediaQuery.of(context).size.width - 40,
              height: 56,
              decoration: ShapeDecoration(
                color: canAddToCart ? const Color(0xFFD09A6C) : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: TextButton(
                onPressed: canAddToCart
                    ? () {
                        if (isPieceAvailable && _pieceQuantity > 0) {
                          final pieceProduct = {
                            'productID': widget.product['ID'],
                            'categoryID': widget.product['categoryID'],
                            'productName': widget.product['productName'] + " (Item)",
                            'image': widget.product['image'],
                            'price': widget.product['price'],
                            'quantity': _pieceQuantity,
                            'upcCode': widget.product['upcCode'],
                            'tax': widget.product['tax'],
                            'type': 'Item',
                            'supplierID': widget.product['supplierID'],  // Include supplier ID here
                          };
                          appState.addToCart(pieceProduct, widget.product['supplier']);
                        }

                        if (isBoxAvailable && _boxQuantity > 0) {
                          final boxProduct = {
                            'productID': widget.product['ID'],
                            'categoryID': widget.product['categoryID'],
                            'productName': widget.product['productName'] + " (Box)",
                            'image': widget.product['image'],
                            'price': widget.product['price'] * widget.product['itemsInBox'],
                            'quantity': _boxQuantity,
                            'upcCode': widget.product['upcCode'],
                            'tax': widget.product['tax'],
                            'type': 'Box',
                            'supplierID': widget.product['supplierID'],  // Include supplier ID here
                          };
                          appState.addToCart(boxProduct, widget.product['supplier']);
                        }

                        Navigator.of(context).pop();
                      }
                    : null,
                child: Center(
                  child: Text(
                    'Add To Cart',
                    style: theme.displaySmall.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    FlutterFlowTheme theme,
    BuildContext context,
    String type,
    int quantity,
    ValueChanged<int> onQuantityChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 59,
          height: 57,
          decoration: ShapeDecoration(
            image: DecorationImage(
              image: NetworkImage(_imageUrl ?? widget.product['image']),
              fit: BoxFit.fill,
              onError: (_, __) {
                _loadImageFromFirebase(); // Attempt to load image from Firebase if NetworkImage fails
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width - 240,
              child: Text(
                type,
                maxLines: 2,
                style: theme.titleMedium?.copyWith(
                  color: const Color(0xFF353934),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '\$${widget.product['price'].toString()}',
              style: theme.bodySmall?.copyWith(
                color: const Color(0xFF353934),
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: quantity > 0
                  ? () {
                      onQuantityChanged(quantity - 1);
                    }
                  : null,
            ),
            Text(
              '$quantity',
              style: theme.headlineMedium?.copyWith(
                color: const Color(0xFF353934),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                onQuantityChanged(quantity + 1);
              },
            ),
          ],
        ),
      ],
    );
  }
}
