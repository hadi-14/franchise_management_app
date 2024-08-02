import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Common/flutter_flow_theme.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  params: const GoogleSignInParams(
    clientId: '1018649504290-9sk31otsj5r3ev4ceib8qs66qklr14oi.apps.googleusercontent.com',
    clientSecret: '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',
    redirectPort: 4321,
  ),
);

class EditCredentialsPage extends StatefulWidget {
  const EditCredentialsPage({super.key});

  @override
  _EditCredentialsPageState createState() => _EditCredentialsPageState();
}

class _EditCredentialsPageState extends State<EditCredentialsPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _displayNameController.text = user.displayName ?? '';
      // Load the user's profile image if available
      // This is just a placeholder as FirebaseAuth does not directly store profile images
      // You can modify this part based on your actual implementation for storing profile images
    }
  }

  Future<void> _updateEmail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.currentUser?.updateEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update email: $e')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateDisplayName() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.currentUser?.updateDisplayName(_displayNameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display Name updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update display name: $e')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Credentials'),
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ),
          Tooltip(
            message: 'Delete Account',
            child: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _confirmDeleteAccount,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.alternate,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, color: theme.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _displayNameController,
                  labelText: 'Display Name',
                  theme: theme,
                  keyboardType: TextInputType.name,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateDisplayName,
                    child: _isLoading
                        ? CircularProgressIndicator(color: theme.primaryText)
                        : const Text('Update Display Name'),
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  theme: theme,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateEmail,
                    child: _isLoading
                        ? CircularProgressIndicator(color: theme.primaryText)
                        : const Text('Update Email'),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required FlutterFlowTheme theme,
    TextInputType? keyboardType,
    List<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        autofillHints: autofillHints,
        obscureText: false,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: theme.labelLarge.override(
            fontFamily: 'Readex Pro',
            letterSpacing: 0.0,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.alternate,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.primary,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.error,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.error,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: theme.secondaryBackground,
          contentPadding: const EdgeInsets.all(24.0),
        ),
        style: theme.bodyLarge.override(
          fontFamily: 'Readex Pro',
          letterSpacing: 0.0,
        ),
        keyboardType: keyboardType,
        cursorColor: theme.primary,
      ),
    );
  }
}
