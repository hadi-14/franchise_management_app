import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_error_widget.dart';
import 'scanned_barcode_label.dart';
import 'scanner_button_widgets.dart';

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
  double _zoomFactor = 0.0;

  Widget _buildZoomScaleSlider() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final TextStyle labelStyle = Theme.of(context)
            .textTheme
            .headlineMedium!
            .copyWith(color: Colors.white);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(
                '0%',
                overflow: TextOverflow.fade,
                style: labelStyle,
              ),
              Expanded(
                child: Slider(
                  value: _zoomFactor,
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
                overflow: TextOverflow.fade,
                style: labelStyle,
              ),
            ],
          ),
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingBarcode) return; // Prevent re-entry if already processing
    final barcode = capture.barcodes.first.rawValue;
    if (barcode != null) {
      setState(() {
        _isProcessingBarcode = true;
      });
      // Show a snackbar indicating that the product was added to the inventory
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product $barcode added to inventory'),
          duration: const Duration(seconds: 2),
        ),
      );
      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, barcode);
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isProcessingBarcode) {
      // Show a message to the user
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
                child: Stack(
                  children: [
                    Positioned(
                      left: 23,
                      top: 165,
                      child: Container(
                        width: size.width - 46,
                        height: size.height * 0.5,
                        decoration: ShapeDecoration(
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
                    Positioned(
                      left: 23,
                      top: 56,
                      child: Container(
                        width: size.width - 46,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Text(
                              'Scan',
                              style: TextStyle(
                                color: Color(0xFF353934),
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 20), // Placeholder for alignment
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 38,
                      top: size.height * 0.75,
                      child: Container(
                        width: size.width - 76,
                        child: Column(
                          children: [
                            _buildZoomScaleSlider(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: size.width * 0.2,
              top: size.height * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD09A6C)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 54),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFD09A6C),
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 54),
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Color(0xFFD09A6C)),
                    onPressed: () {},
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
