import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import '../.env.dart';
import '../Common/flutter_flow_theme.dart';
import 'verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  bool _isPasswordVisible = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late GoogleSignIn _googleSignIn;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      params: const GoogleSignInParams(
        clientId:
            '1018649504290-9sk31otsj5r3ev4ceib8qs66qklr14oi.apps.googleusercontent.com',
        clientSecret: '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',
        redirectPort: 4321,
      ),
    );
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  Future<void> _signUpWithEmail() async {
    try {
      // Send email for verification
      await _sendVerificationEmail(
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        address: {
          'city': _cityController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'street': _streetController.text,
          'zip': int.parse(_zipController.text),
        },
      );

        // Navigate to verification pending page
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const VerificationPendingPage()),
        );
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleAuth = await _googleSignIn.signInOnline();

      if (googleAuth != null) {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      // Handle error
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
    required String company,
    required Map<String, dynamic> address,
  }) async {
    final link =
        'https://franchise-management-server.vercel.app/verify?email=$email&name=$displayName&phone=$phone&company=$company&address=${json.encode(address)}';
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 16.0),
                child: Text(
                  'Franchise Management',
                  style: theme.displaySmall.override(
                    fontFamily: 'Outfit',
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 12.0, 0.0, 12.0),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.8,
                      constraints: const BoxConstraints(
                        maxWidth: 530.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 16.0, 0.0, 0.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildCreateAccountTab(theme),
                                  _buildLoginTab(theme),
                                ],
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0.0, 0),
                              child: TabBar(
                                labelStyle: theme.bodyLarge.override(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                unselectedLabelStyle: theme.bodyLarge.override(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0.0,
                                ),
                                labelColor: theme.primaryText,
                                unselectedLabelColor: theme.secondaryText,
                                labelPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                tabs: const [
                                  Tab(text: 'Create Account'),
                                  Tab(text: 'Log In'),
                                ],
                                controller: _tabController,
                                onTap: (i) {},
                              ),
                            ),
                          ],
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

  Widget _buildCreateAccountTab(FlutterFlowTheme theme) {
    return Align(
      alignment: const AlignmentDirectional(0.0, -1.0),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 0.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (MediaQuery.of(context).size.width >= 600)
                Container(
                  width: 230.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                  ),
                ),
              Text(
                'Create Account',
                textAlign: TextAlign.start,
                style: theme.headlineMedium.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 24.0),
                child: Text(
                  'Let\'s get started by filling out the form below.',
                  textAlign: TextAlign.start,
                  style: theme.labelMedium.override(
                    fontFamily: 'Readex Pro',
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
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
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _displayNameController,
                labelText: 'Display Name',
                theme: theme,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              _buildTextField(
                controller: _phoneController,
                labelText: 'Phone',
                theme: theme,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                theme: theme,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              _buildTextField(
                controller: _companyController,
                labelText: 'CompanyName',
                theme: theme,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              const Divider(
                height: 10,
              ),
              _buildTextField(
                labelText: 'City',
                controller: _cityController,
                theme: theme,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.addressCity],
              ),
              _buildTextField(
                labelText: 'State',
                controller: _stateController,
                theme: theme,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.addressState],
              ),
              _buildTextField(
                labelText: 'Country',
                controller: _countryController,
                theme: theme,
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.countryName],
              ),
              _buildTextField(
                labelText: 'Street',
                controller: _streetController,
                theme: theme,
                keyboardType: TextInputType.streetAddress,
                autofillHints: const [AutofillHints.fullStreetAddress],
              ),
              _buildTextField(
                labelText: 'Zip',
                controller: _zipController,
                theme: theme,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signUpWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: theme.titleSmall.override(
                        fontFamily: 'Readex Pro',
                        color: theme.primaryText,
                        letterSpacing: 0.0,
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

  Widget _buildLoginTab(FlutterFlowTheme theme) {
    return Align(
      alignment: const AlignmentDirectional(0.0, -1.0),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 0.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (MediaQuery.of(context).size.width >= 600)
                Container(
                  width: 230.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                  ),
                ),
              Text(
                'Welcome Back',
                textAlign: TextAlign.start,
                style: theme.headlineMedium.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 24.0),
                child: Text(
                  'Fill out the information below in order to access your account.',
                  textAlign: TextAlign.start,
                  style: theme.labelMedium.override(
                    fontFamily: 'Readex Pro',
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                theme: theme,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              _buildPasswordField(
                controller: _passwordController,
                labelText: 'Password',
                theme: theme,
                autofillHints: const [AutofillHints.password],
                isPasswordVisible: _isPasswordVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: theme.titleSmall.override(
                        fontFamily: 'Readex Pro',
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
              ),
              _buildSocialSignInButtons(theme),
            ],
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
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: controller,
          autofocus: true,
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required FlutterFlowTheme theme,
    List<String>? autofillHints,
    required bool isPasswordVisible,
    required void Function() togglePasswordVisibility,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          autofillHints: autofillHints,
          obscureText: !isPasswordVisible,
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
            suffixIcon: InkWell(
              onTap: togglePasswordVisibility,
              focusNode: FocusNode(skipTraversal: true),
              child: Icon(
                isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.secondaryText,
                size: 24.0,
              ),
            ),
          ),
          style: theme.bodyLarge.override(
            fontFamily: 'Readex Pro',
            letterSpacing: 0.0,
          ),
          cursorColor: theme.primary,
        ),
      ),
    );
  }

  Widget _buildSocialSignInButtons(FlutterFlowTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 24.0),
            child: Text(
              'Or sign in with',
              textAlign: TextAlign.center,
              style: theme.labelMedium.override(
                fontFamily: 'Readex Pro',
                letterSpacing: 0.0,
              ),
            ),
          ),
        ),
        Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 0.0,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            direction: Axis.horizontal,
            runAlignment: WrapAlignment.center,
            verticalDirection: VerticalDirection.down,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: Text(
                    'Continue with Google',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.primary,
                    backgroundColor: theme.primaryBackground,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    side: BorderSide(
                      color: theme.primary,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
