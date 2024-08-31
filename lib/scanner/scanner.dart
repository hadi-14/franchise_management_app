import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../Common/user_state.dart';
import '../product/add_products.dart';
import 'scanner_error_widget.dart';

class BarcodeScannerWithZoom extends StatefulWidget {
  const BarcodeScannerWithZoom({super.key});

  @override
  State<BarcodeScannerWithZoom> createState() => _BarcodeScannerWithZoomState();
}

class _BarcodeScannerWithZoomState extends State<BarcodeScannerWithZoom>
    with AutomaticKeepAliveClientMixin {
  final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
  );

  bool _isProcessingBarcode = false;
  bool _allowScan = false; // Controls when scanning is allowed
  double _zoomFactor = 0.0;
  List<Map<String, String>> _scannedProducts = []; // Stores UPC code and product names

  @override
  void initState() {
    controller.start(); // Ensure the camera preview is always on
    super.initState();
  }

  Future<void> _fetchProductName(String barcode) async {
    final userState = Provider.of<UserState>(context, listen: false);
    final CollectionReference productsCollection = FirebaseFirestore.instance
        .collection('product')
        .doc(userState.franchiseID)
        .collection('list');

    try {
      final querySnapshot = await productsCollection
          .where('upcCode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final productName = querySnapshot.docs.first['productName'] as String;
        setState(() {
          _scannedProducts.insert(0, {'upcCode': barcode, 'productName': productName});
          if (_scannedProducts.length > 5) {
            _scannedProducts = _scannedProducts.sublist(0, 5);
          }
        });
      } else {
        // Show a dialog if no product is found
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      print('Error fetching product name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching product name: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessingBarcode || !_allowScan) return; // Prevent re-entry if already processing or not allowed to scan
    final barcode = capture.barcodes.first.rawValue;
    if (barcode != null) {
      setState(() {
        _isProcessingBarcode = true;
        _allowScan = false; // Disallow further scanning until button is pressed again
      });
      await _fetchProductName(barcode); // Fetch product name using the barcode
      setState(() {
        _isProcessingBarcode = false;
      });
    }
  }

  void _enableScan() {
    setState(() {
      _allowScan = true; // Enable scanning for one barcode
    });
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Product Not Found'),
          content: const Text('No product found with this UPC code. Would you like to add a new product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProducts(
                      productData: {'upcCode': barcode}, // Pass the UPC code to the AddProducts page
                    ),
                  ),
                );
              },
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoomScaleSlider() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(
                '0%',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _zoomFactor,
                  activeColor: const Color(0xFFD09A6C),
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) {
                    setState(() {
                      _zoomFactor = value;
                      controller.setZoomScale(value);
                    });
                  },
                ),
              ),
              Text(
                '100%',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannedProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _scannedProducts.length,
      itemBuilder: (context, index) {
        final product = _scannedProducts[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            title: Text(
              product['productName'] ?? 'Unknown Product',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: Color(0xFF353934),
              ),
            ),
            subtitle: Text(
              'UPC: ${product['upcCode']}',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Color(0xFF707070),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_isProcessingBarcode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing barcode, please wait...')),
      );
      return false; // Prevent navigation
    }
    return true; // Allow navigation
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Scan'),
        backgroundColor: const Color(0xFFD09A6C),
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Column(
          children: [
            // Camera preview with full width
            Container(
              width: size.width,
              height: size.height * 0.5, // Adjusted height for the camera preview
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: size.width,
                      height: size.height * 0.4,
                      margin: const EdgeInsets.all(20),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(width: 1, color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: MobileScanner(
                        controller: controller,
                        fit: BoxFit.contain,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return ScannerErrorWidget(error: error);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scanned history list with full width in a rounded container
            Expanded(
              child: Container(
                width: size.width,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scanned History',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: _buildScannedProductsList(), // Display scanned products list
                    ),
                  ],
                ),
              ),
            ),
            // Camera controls with zoom slider
            Container(
              width: size.width,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildZoomScaleSlider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Color(0xFFD09A6C)),
                        onPressed: () {
                          controller.switchCamera();
                        },
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFD09A6C),
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _enableScan, // Allow scanning when camera button is pressed
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Color(0xFFD09A6C)),
                        onPressed: () {
                          controller.toggleTorch();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> dispose() async {
    await controller.dispose();
    super.dispose();
  }
}
