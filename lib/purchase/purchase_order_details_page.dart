import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Common/flutter_flow_theme.dart';

class PurchaseOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const PurchaseOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Order Details', style: theme.headlineMedium),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('purchase')
            .doc(user?.uid)
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

          final items = data['items'] as List<dynamic> ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${data['OrderID']}', style: theme.headlineMedium),
                Text('Store ID: ${data['StoreID']}', style: theme.headlineMedium),
                Text('State: ${data['State']}', style: theme.headlineMedium),
                Text('Total Amount: \$${data['TotalAmount']}', style: theme.headlineMedium),
                Text('Tax: ${data['Tax']}%', style: theme.headlineMedium),
                const SizedBox(height: 16),
                Text('Items:', style: theme.headlineMedium),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text('Product: ${item['Product']}', style: theme.bodyLarge),
                          subtitle: Text('Quantity: ${item['Quantity']}\nUnit Price: \$${item['UnitPrice']}\nTotal: \$${item['Total']}', style: theme.bodyLarge),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
