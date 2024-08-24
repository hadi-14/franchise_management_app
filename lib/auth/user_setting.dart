import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class UserSetting extends StatefulWidget {
  const UserSetting({super.key});

  @override
  _UserSettingState createState() => _UserSettingState();
}

class _UserSettingState extends State<UserSetting> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _displayNameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = userDoc['phoneNumber'] ?? '';
      });
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'phoneNumber': _phoneController.text,
      });

      await user.updateEmail(_emailController.text);

      await user.updateDisplayName(_displayNameController.text);

      if (_profileImage != null) {
        // Upload image and update user's photo URL
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
          child: Stack(
            children: [
              Positioned(
                left: (screenWidth - 75) / 2,
                top: screenHeight * 0.1,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 37.5,
                        backgroundColor: theme.primaryColor,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.secondary,
                                      width: 1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox(),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: theme.secondary,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.07,
                left: (screenWidth - 314) / 2,
                child: const SizedBox(
                  width: 314,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'User Profile',
                        style: TextStyle(
                          color: Color(0xFF353934),
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.25,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      _displayNameController.text,
                      style: const TextStyle(
                        color: Color(0xFF353934),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                        color: Color(0xFF8E918D),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 26,
                top: screenHeight * 0.35,
                child: Container(
                  width: screenWidth - 52,
                  child: Column(
                    children: [
                      _buildEditableSettingOption(
                        context,
                        'Display Name',
                        'assets/Icons/Create Account/user.png',
                        _displayNameController,
                      ),
                      const SizedBox(height: 10),
                      _buildEditableSettingOption(
                        context,
                        'Email',
                        "assets/Icons/Create Account/email.png",
                        _emailController,
                      ),
                      const SizedBox(height: 10),
                      _buildEditableSettingOption(
                        context,
                        'Phone Number',
                        "assets/Icons/Create Account/phone.png",
                        _phoneController,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: screenHeight * 0.8,
                child: Container(
                  width: screenWidth - 32,
                  height: 56,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD09A6C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: _saveChanges,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSettingOption(BuildContext context, String label,
      String imageUrl, TextEditingController controller) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth - 52,
      height: 63,
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadows: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              child: Image.asset(imageUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E918D),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
