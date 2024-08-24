import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:franchise_management_app/auth/signup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Common/flutter_flow_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacementNamed(context, '/homePage');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      Navigator.pushReplacementNamed(context, '/homePage');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showMessage('Password reset link has been sent to your email');
    } catch (e) {
      print(e);
      _showMessage('Failed to send password reset email');
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 48.0, 0.0, 16.0),
              child: Center(
                child: Text(
                  'Login',
                  style: theme.titleLarge.override(
                    color: theme.primaryText,
                    fontFamily: 'Outfit',
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0),
              child: Text(
                'Welcome Back',
                style: theme.displaySmall.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0, 0.0, 32.0),
              child: Text(
                'Please enter your email and password to sign in.',
                style: theme.bodySmall.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextFormField(
                      theme: theme,
                      screenWidth: screenWidth,
                      icon: 'assets/Icons/Create Account/email.png',
                      label: 'Email',
                      controller: _emailController,
                      isPassword: false,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: () {},
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      theme: theme,
                      screenWidth: screenWidth,
                      icon: 'assets/Icons/Create Account/padlock.png',
                      label: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      togglePasswordVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width - 180, 8, 0, 16),
                      child: InkWell(
                        onTap: _resetPassword,
                        child: const Text(
                          "Forgot Password?",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
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
                          'Login In',
                          style: theme.titleSmall.override(
                            fontFamily: 'Readex Pro',
                            color: theme.primaryText,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialSignInButtons(theme),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0, 0.0, 32.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Don’t have an account?',
                            style: theme.labelMedium.override(
                              fontFamily: 'Outfit',
                              letterSpacing: 0.0,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                            child: Text(
                              ' Create Account',
                              style: theme.labelMedium.override(
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                                fontFamily: 'Outfit',
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required FlutterFlowTheme theme,
    required double screenWidth,
    required String icon,
    required String label,
    required TextEditingController controller,
    required bool isPassword,
    required bool isPasswordVisible,
    required void Function() togglePasswordVisibility,
  }) {
    return Container(
      width: screenWidth * 0.85,
      height: 63,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 10),
            blurRadius: 15,
          ),
        ],
        color: theme.secondaryBackground,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Image.asset(
              icon,
              width: 18,
              height: 18,
              fit: BoxFit.fitWidth,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: theme.labelLarge.override(
                  fontFamily: 'Poppins',
                  color: theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                suffixIcon: isPassword
                    ? InkWell(
                        onTap: togglePasswordVisibility,
                        child: Icon(
                          isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: theme.secondaryText,
                          size: 24.0,
                        ),
                      )
                    : null,
              ),
              style: theme.bodyLarge.override(
                fontFamily: 'Readex Pro',
                letterSpacing: 0.0,
              ),
            ),
          ),
        ],
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
            child: Stack(
              children: [
                Divider(
                  color: theme.primaryText,
                ),
                Center(
                  child: Container(
                    color: theme.primaryBackground,
                    height: 20,
                    width: 60,
                    child: Text(
                      'OR',
                      textAlign: TextAlign.center,
                      style: theme.labelMedium.override(
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ),
              ],
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
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0, 0.0, 0.0, 16.0),
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset(
                    "assets/Icons/Login Page/google.png",
                    width: 20,
                    fit: BoxFit.fitWidth,
                  ),
                  label: Text(
                    'Login with Google',
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
                        vertical: 16.0, horizontal: 48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    side: BorderSide(
                      color: theme.secondaryText,
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
