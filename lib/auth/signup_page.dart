import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../.env.dart';
import '../Common/flutter_flow_theme.dart';
import 'verification_page.dart';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  File? _profileImage;

  Future<void> _signUpWithEmail() async {
    try {
      await _sendVerificationEmail(
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: {
          'city': _cityController.text,
          'state': _stateController.text,
          'zip': int.parse(_zipController.text),
        },
      );

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const VerificationPendingPage()),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _sendVerificationEmail({
    required String email,
    required String displayName,
    required String phone,
    required Map<String, dynamic> address,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final response = await http.post(
        Uri.parse(kApiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'displayName': displayName,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        print('Verification email sent successfully via API');
      } else {
        print(
            'Failed to send verification email via API: ${response.statusCode}');
      }
    } else {
      final link =
          '$kApiUrl/verify?email=$email&name=$displayName&phone=$phone&address=${json.encode(address)}';
      final smtpServer =
          SmtpServer('smtp.gmail.com', username: smtp_mail, password: smtp_pass);

      final message = Message()
        ..from = const Address(smtp_mail, 'Franchise Manager')
        ..recipients.add(mailTo)
        ..subject = 'Account Verification'
        ..text = 'Please verify your account by clicking the link: $link';

      try {
        final sendReport = await send(message, smtpServer);
        print('Message sent: ' + sendReport.toString());
      } on MailerException catch (e) {
        print('Message not sent. \n' + e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 37.5,
                        backgroundColor: theme.primaryText,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.secondaryBackground,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.secondaryBackground,
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
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildInputField(
                controller: _displayNameController,
                labelText: 'Display Name',
                icon: 'assets/Icons/Create Account/user.png',
                theme: theme,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              _buildInputField(
                controller: _emailController,
                labelText: 'Email',
                icon: 'assets/Icons/Create Account/email.png',
                theme: theme,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              _buildInputField(
                controller: _passwordController,
                labelText: 'Password',
                icon: 'assets/Icons/Create Account/padlock.png',
                theme: theme,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              _buildInputField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                icon: 'assets/Icons/Create Account/padlock.png',
                theme: theme,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
              ),
              _buildInputField(
                controller: _phoneController,
                labelText: 'Phone Number',
                icon: 'assets/Icons/Create Account/phone.png',
                theme: theme,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              _buildInputField(
                controller: _cityController,
                labelText: 'City',
                icon: 'assets/Icons/Create Account/location.png',
                theme: theme,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.addressCity],
              ),
              _buildInputField(
                controller: _stateController,
                labelText: 'State',
                icon: 'assets/Icons/Create Account/home.png',
                theme: theme,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.addressState],
              ),
              _buildInputField(
                controller: _zipController,
                labelText: 'Postal Code',
                icon: 'assets/Icons/Create Account/hashtag.png',
                theme: theme,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    20.0, 30.0, 20.0, 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signUpWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: theme.secondaryBackground,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Color(0xFF353934),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String icon,
    required FlutterFlowTheme theme,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Container(
        width: double.infinity,
        height: 63,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
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
              padding: const EdgeInsets.only(left: 21.0),
              child: Image.asset(
                icon,
                width: 18,
                height: 18,
                fit: BoxFit.fill,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                autofillHints: autofillHints,
                decoration: InputDecoration(
                  labelText: labelText,
                  labelStyle: TextStyle(
                    color: theme.primaryText,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
                keyboardType: keyboardType,
                style: const TextStyle(
                  color: Color(0xFF353934),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
