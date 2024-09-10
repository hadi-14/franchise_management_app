import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'suppliers_details_page.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  _SuppliersPageState createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchSuppliers(String franchiseID) async {
    QuerySnapshot snapshot = await _firestore
        .collection('suppliers')
        .where('companyID', isEqualTo: franchiseID)
        .get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final userState = Provider.of<UserState>(context,
        listen: false); // Get the franchiseID from UserState

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          "Suppliers",
          style: theme.titleMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchSuppliers(
              userState.franchiseID), // Pass franchiseID from UserState
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final suppliers = snapshot.data ?? [];

            if (suppliers.isEmpty) {
              return const Center(child: Text('No suppliers found.'));
            }

            return ListView.builder(
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return _buildSupplierCard(
                    context, theme, screenWidth, supplier);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSuppliesInformation(),
            ),
          );
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Supplier Card Widget
  Widget _buildSupplierCard(
    BuildContext context,
    FlutterFlowTheme theme,
    double screenWidth,
    Map<String, dynamic> supplier,
  ) {
    final address = supplier['address'];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Name and ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                supplier['name'] ?? 'Unknown',
                style: theme.bodyText1.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText),
              ),
              Text(
                'ID: ${supplier['ID'] ?? ''}',
                style: theme.bodyText2
                    .copyWith(fontSize: 14, color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Email and Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                supplier['email'] ?? 'No email',
                style: theme.bodyText2.copyWith(color: theme.primaryText),
              ),
              Text(
                supplier['phone'] ?? 'No phone',
                style: theme.bodyText2.copyWith(color: theme.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Website and Address
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                supplier['website'] ?? 'No website',
                style: theme.bodyText2.copyWith(color: theme.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${address['street']}, ${address['city']}, ${address['state']}, ${address['country']}, ${address['zip']}',
            style: theme.bodyText2.copyWith(color: theme.secondaryText),
          ),

          // Remove buttons
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
