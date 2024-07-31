import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_password_generator/random_password_generator.dart';
import '../../Common/flutter_flow_theme.dart';
import '../main.dart';

class CompanyDetailsPage extends StatefulWidget {
  const CompanyDetailsPage({super.key});

  @override
  _CompanyDetailsPageState createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();

  String? _verificationId;
  final _passwordGenerator = RandomPasswordGenerator();

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
    _loadUserDetails();
  }

  Future<void> _loadCompanyDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot =
          await _firestore.collection('user').doc(user.uid).get();
      final data = docSnapshot.data();
      if (data != null) {
        _companyNameController.text = data['Company'] ?? '';
        _websiteController.text = data['Website'] ?? '';
      }
    }
  }

  Future<void> _loadUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      _usernameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _updateCompanyDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('user').doc(user.uid).set({
        'Company': _companyNameController.text,
        'Website': _websiteController.text,
      });
    }
  }

  Future<void> _verifyPhoneNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.currentUser?.updatePhoneNumber(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Phone number automatically verified and updated')),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification code sent to $phone')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    }
  }

  Future<void> _updatePhoneNumber(String smsCode) async {
    if (_verificationId != null) {
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        await _auth.currentUser?.updatePhoneNumber(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update phone number: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('user').doc(user.uid).delete();
      await user.delete();
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()), // Replace 'MyApp' with the main widget in main.dart
    );
  }

  Future<void> _inviteUser() async {
      final user = _auth.currentUser;
    final inviteEmail = _inviteEmailController.text.trim();
    if (inviteEmail.isNotEmpty) {
      try {
        final randomPassword = _passwordGenerator.randomPassword(
          letters: true,
          uppercase: true,
          numbers: true,
          specialChar: true,
          passwordLength: 12,
        );

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: inviteEmail,
          password: randomPassword,
        );
        final docSnapshot =
            await _firestore.collection('user').doc(user!.uid).get();
        final data = docSnapshot.data();
        
        // Set user role and franchise ID in Firestore
        await _firestore.collection('user').doc(userCredential.user?.uid).set({
          'role': 'staff',
          'franchiseId': data!['franchiseId'], // Replace with actual franchise ID
        });

        await _auth.sendPasswordResetEmail(email: inviteEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $inviteEmail')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitation: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Details', style: theme.headlineMedium),
        backgroundColor: theme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.primaryBackground),
            onPressed: _signOut,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: theme.primaryBackground),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                _deleteAccount();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Company Name', _companyNameController, theme),
              _buildTextField('Website', _websiteController, theme),
              const Divider(),
              _buildTextField('Username', _usernameController, theme),
              _buildTextField('Phone', _phoneController, theme),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyPhoneNumber,
                child: const Text('Verify Phone Number'),
              ),
              if (_verificationId != null) ...[
                _buildTextField(
                    'SMS Code', _smsCodeController, theme, isNumeric: true),
                ElevatedButton(
                  onPressed: () =>
                      _updatePhoneNumber(_smsCodeController.text.trim()),
                  child: const Text('Update Phone Number'),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _updateCompanyDetails();
                  _updateUserDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Details updated successfully')),
                  );
                },
                child: const Text('Update Details'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Invite User to Franchise', style: theme.headlineSmall),
              const SizedBox(height: 8),
              _buildTextField('Invite Email', _inviteEmailController, theme),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _inviteUser,
                child: const Text('Send Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      FlutterFlowTheme theme,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.labelLarge,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.alternate, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.primary, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        style: theme.bodyLarge,
      ),
    );
  }

  Future<void> _updateUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(_usernameController.text);
      // Phone number is updated via verification process
      _auth.currentUser?.reload();
    }
  }
}
