import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Common/user_state.dart';

class SalesOrderDetailsPage extends StatelessWidget {
  final String orderId;
  const SalesOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = Provider.of<UserState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('sales')
              .doc(userState.franchiseID)
              .collection('list')
              .doc(orderId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading order details'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Order not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OrderID: ${data['OrderID']}', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Store: ${data['StoreID']}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('State: ${data['State']}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Total Amount: \$${data['TotalAmount']}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Tax: ${data['Tax']}%', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Net Total: \$${data['NetTotal']}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Date: ${data['Date'].toDate()}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: (data['items'] as List).length,
                    itemBuilder: (context, index) {
                      final item = (data['items'] as List)[index];
                      return ListTile(
                        title: Text('Product: ${item['Product']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${item['Category']}'),
                            Text('Quantity: ${item['Quantity']}'),
                            Text('Unit Price: \$${item['UnitPrice']}'),
                            Text('Total: \$${item['Total']}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
