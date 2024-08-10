import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanned_barcode_label.dart';
import 'scanner_button_widgets.dart';
import 'scanner_error_widget.dart';

class BarcodeScannerWithZoom extends StatefulWidget {
  const BarcodeScannerWithZoom({super.key});

  @override
  State<BarcodeScannerWithZoom> createState() => _BarcodeScannerWithZoomState();
}

class _BarcodeScannerWithZoomState extends State<BarcodeScannerWithZoom> with AutomaticKeepAliveClientMixin {
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
      Navigator.pop(context, barcode);
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('With zoom slider')),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: controller,
              fit: BoxFit.contain,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return ScannerErrorWidget(error: error);
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.bottomCenter,
                height: 100,
                color: Colors.black.withOpacity(0.4),
                child: Column(
                  children: [
                    if (!kIsWeb) _buildZoomScaleSlider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ToggleFlashlightButton(controller: controller),
                        StartStopMobileScannerButton(controller: controller),
                        Expanded(
                          child: Center(
                            child: ScannedBarcodeLabel(
                              barcodes: controller.barcodes,
                            ),
                          ),
                        ),
                        SwitchCameraButton(controller: controller),
                        AnalyzeImageFromGalleryButton(controller: controller),
                      ],
                    ),
                  ],
                ),
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
