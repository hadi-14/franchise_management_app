import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_password_generator/random_password_generator.dart';
import '../../Common/flutter_flow_theme.dart';
import '../main.dart';

class CompanyDetailsPage extends StatefulWidget {
  final String franchiseID;

  const CompanyDetailsPage({super.key, required this.franchiseID});

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
  String? _selectedRole;
  final _passwordGenerator = RandomPasswordGenerator();
  final List<String> _roles = ['staff', 'franchisee'];

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
    _loadUserDetails();
  }

  Future<void> _loadCompanyDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore.collection('user').doc(user.uid).get();
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
      }, SetOptions(merge: true));
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
            const SnackBar(content: Text('Phone number automatically verified and updated')),
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
    final inviteEmail = _inviteEmailController.text.trim();
    if (inviteEmail.isNotEmpty && _selectedRole != null) {
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

        // Set user role and franchise ID in Firestore
        await _firestore.collection('user').doc(userCredential.user?.uid).set({
          'role': _selectedRole,
          'franchiseID': widget.franchiseID,
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

  Future<void> _updateUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(_usernameController.text);
      // Phone number is updated via verification process
      _auth.currentUser?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Details', style: theme.headlineMedium),
        backgroundColor: theme.primary,
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: Icon(Icons.logout, color: theme.primaryBackground),
              onPressed: _signOut,
            ),
          ),
          Tooltip(
            message: 'Delete Account',
            child: IconButton(
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text('Email: ${user.email}', style: theme.bodyLarge),
                const SizedBox(height: 8),
                _buildTextField('Display Name', _usernameController, theme),
                const SizedBox(height: 8),
                Text('Phone: ${user.phoneNumber ?? 'Not Provided'}', style: theme.bodyLarge),
                const SizedBox(height: 8),
              ],
              const Divider(),
              _buildTextField('Company Name', _companyNameController, theme),
              _buildTextField('Website', _websiteController, theme),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyPhoneNumber,
                child: const Text('Verify Phone Number'),
              ),
              if (_verificationId != null) ...[
                _buildTextField('SMS Code', _smsCodeController, theme, isNumeric: true),
                ElevatedButton(
                  onPressed: () => _updatePhoneNumber(_smsCodeController.text.trim()),
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
              _buildDropdown('Select Role', _roles, (value) {
                setState(() {
                  _selectedRole = value;
                });
              }),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _inviteUser,
                child: const Text('Send Invite'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Invited Users', style: theme.headlineSmall),
              const SizedBox(height: 8),
              _buildInvitedUsersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, FlutterFlowTheme theme, {bool isNumeric = false}) {
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

  Widget _buildDropdown(String label, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInvitedUsersTable() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('user')
          .where('franchiseID', isEqualTo: widget.franchiseID)
          .where('role', isNotEqualTo: 'owner') // Assuming 'owner' is the role for the franchise owner
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data?.docs ?? [];

        return DataTable(
          columns: const [
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
          ],
          rows: data.map((doc) {
            final userData = doc.data() as Map<String, dynamic>;
            return DataRow(cells: [
              DataCell(Text(userData['email'] ?? '')),
              DataCell(Text(userData['role'] ?? '')),
            ]);
          }).toList(),
        );
      },
    );
  }
}
