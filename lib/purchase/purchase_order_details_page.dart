import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'dart:io';

class PurchaseOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const PurchaseOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Order Details', style: theme.headlineMedium),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('purchase')
            .doc(userState.franchiseID)
            .collection('list')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: theme.bodyLarge));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text('No data found', style: theme.bodyLarge));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${data['OrderID']}', style: theme.headlineMedium),
                Text('Store Name: ${data['StoreID']}', style: theme.headlineMedium),
                Text('State: ${data['State']}', style: theme.headlineMedium),
                Text('Total Amount: \$${data['TotalAmount']}', style: theme.headlineMedium),
                Text('Tax: ${data['Tax']}%', style: theme.headlineMedium),
                const SizedBox(height: 16),
                Text('Items:', style: theme.headlineMedium),
                Expanded(
                  child: ListView.builder(
                    itemCount: data['items'].length,
                    itemBuilder: (context, index) {
                      final item = data['items'][index] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text('Product: ${item['Product']}', style: theme.bodyLarge),
                          subtitle: Text('Quantity: ${item['Quantity']}\nUnit Price: \$${item['UnitPrice']}\nTotal: \$${item['Total']}', style: theme.bodyLarge),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _downloadInvoice(context, userState.franchiseID, orderId);
                  },
                  child: const Text('Download Invoice as PDF'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadInvoice(BuildContext context, String franchiseID, String orderId) async {
    final orderSnapshot = await FirebaseFirestore.instance
        .collection('purchase')
        .doc(franchiseID)
        .collection('list')
        .doc(orderId)
        .get();

    final orderData = orderSnapshot.data();
    if (orderData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No order data found')),
      );
      return;
    }

    final items = orderData['items'] as List<dynamic>? ?? [];
    final storeId = orderData['StoreID'] as String;

    final storeSnapshot = await FirebaseFirestore.instance
        .collection('store')
        .doc(franchiseID)
        .collection('list')
        .doc(storeId)
        .get();

    final storeData = storeSnapshot.data();
    final storeName = storeData?['Name'] ?? 'Unknown';

    final pdf = pw.Document();

    final tableData = await Future.wait(items.map((item) async {
      final itemData = item as Map<String, dynamic>;
      final productSnapshot = await FirebaseFirestore.instance
          .collection('product')
          .doc(franchiseID)
          .collection('list')
          .doc(itemData['Product'])
          .get();
      final productData = productSnapshot.data();
      final productName = productData?['productName'] ?? 'Unknown';

      return [
        productName,
        itemData['isBox'] ? 'Box' : 'Unit',
        itemData['isBox'] ? itemData['piecesPerBox'].toString() : '-',
        itemData['Quantity'].toString(),
        itemData['UnitPrice'].toString(),
        itemData['Total'].toString(),
      ];
    }).toList());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Purchase Order Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Order ID: ${orderData['OrderID']}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Store Name: $storeName', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('State: ${orderData['State']}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Total Amount: \$${orderData['TotalAmount']}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Tax: ${orderData['Tax']}%', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Text('Items:', style: const pw.TextStyle(fontSize: 18)),
            pw.Table.fromTextArray(
              headers: ['Product', 'Type', 'Pieces', 'Quantity', 'Unit Price', 'Total'],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 16),
              border: pw.TableBorder.all(),
            ),
          ],
        ),
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: 'invoice_${orderData['OrderID']}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      initialDirectory: directory.path,
    );

    if (filePath == null) {
      return;
    }

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to $filePath')),
    );
  }
}
