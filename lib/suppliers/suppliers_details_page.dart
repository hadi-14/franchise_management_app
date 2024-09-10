import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/user_state.dart';

class AddSuppliesInformation extends StatefulWidget {
  const AddSuppliesInformation({Key? key}) : super(key: key);

  @override
  _AddSuppliesInformationState createState() => _AddSuppliesInformationState();
}

class _AddSuppliesInformationState extends State<AddSuppliesInformation> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String supplierName = '';
  String email = '';
  String phoneNumber = '';
  String website = '';
  String streetAddress = '';
  String city = '';
  String postalCode = '';
  String state = '';
  String country = '';

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final userState = Provider.of<UserState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Supplier'),
        backgroundColor: const Color(0xFFB5733B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(context, 'Supplier Name', 'Enter supplier name', 'assets/Icons/Create Account/user.png', (value) {
                  supplierName = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Email', 'Enter email', 'assets/Icons/Create Account/email.png', (value) {
                  email = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Phone Number', 'Enter phone number', 'assets/Icons/Create Account/phone.png', (value) {
                  phoneNumber = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Website', 'Enter website URL', 'assets/Icons/Create Account/website.png', (value) {
                  website = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Street Address', 'Enter street address', 'assets/Icons/Create Account/location.png', (value) {
                  streetAddress = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'City', 'Enter city', 'assets/Icons/Create Account/location.png', (value) {
                  city = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Postal Code', 'Enter postal code', 'assets/Icons/Create Account/hashtag.png', (value) {
                  postalCode = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'State', 'Enter state', 'assets/Icons/Create Account/home.png', (value) {
                  state = value!;
                }),
                const SizedBox(height: 20),
                _buildTextField(context, 'Country', 'Enter country', 'assets/Icons/Create Account/location.png', (value) {
                  country = value!;
                }),
                const SizedBox(height: 30),
                _buildSubmitButton(context, userState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build the text field
  Widget _buildTextField(BuildContext context, String label, String placeholder, String iconPath, Function(String?) onSaved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF353934),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 63,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 15,
                offset: Offset(0, 10),
                spreadRadius: 0,
              )
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Image.asset(
                  iconPath,
                  width: 18,
                  height: 18,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSaved: onSaved,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  },
                  style: const TextStyle(
                    color: Color(0xFF8E918D),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build the submit button
  Widget _buildSubmitButton(BuildContext context, UserState userState) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await _addSupplierToFirestore(userState.franchiseID);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB5733B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Add Supplier',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  // Method to add supplier to Firestore
  Future<void> _addSupplierToFirestore(String franchiseID) async {
    final CollectionReference suppliersCollection = FirebaseFirestore.instance.collection('suppliers');

    // Get the latest supplier ID
    QuerySnapshot snapshot = await suppliersCollection.orderBy('ID', descending: true).limit(1).get();
    int nextID = snapshot.docs.isNotEmpty ? (snapshot.docs.first['ID'] as int) + 1 : 1;

    // Create supplier data
    final supplierData = {
      'ID': nextID,
      'name': supplierName,
      'email': email,
      'website': website,
      'phone': phoneNumber,
      'address': {
        'street': streetAddress,
        'city': city,
        'state': state,
        'country': country,
        'zip': postalCode,
      },
      'companyID': franchiseID, // Franchise ID as companyID
    };

    // Add to Firestore
    await suppliersCollection.add(supplierData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Supplier added successfully!')),
    );
  }
}
