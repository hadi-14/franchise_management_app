import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class DrawerWidget extends StatelessWidget {
  DrawerWidget({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final theme = FlutterFlowTheme.of(context);

    Future<void> _signOut() async {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }

    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFFFAFAFA),
        child: Stack(
          children: [
            Positioned(
              left: MediaQuery.of(context).size.width * 0.1,
              top: 76,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    child: Image.network(userState.profilePhoto),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    userState.userName,
                    style: const TextStyle(
                      color: Color(0xFF353934),
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 1,
              top: 158.76,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: const ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: Color(0xFFE2E4E9),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: MediaQuery.of(context).size.height - 230,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: const ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: Color(0xFFE2E4E9),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.1,
              top: 208,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDrawerMenuItem(
                    context,
                    'Order History',
                    "assets/Icons/order-history.png",
                    '/order-history',
                  ),
                  const SizedBox(height: 20),

                  // If the user is an owner or staff, show additional options
                  if (userState.role == 'owner' || userState.role == 'staff') ...[
                    _buildDrawerMenuItem(
                      context,
                      'Purchase Orders',
                      "assets/Icons/Navigation bar/order-history-unactive.png",
                      '/purchase-orders', // Add route for purchase orders
                    ),
                    const SizedBox(height: 20),
                    _buildDrawerMenuItem(
                      context,
                      'Suppliers',
                      "assets/Icons/Navigation bar/order-history-unactive.png",
                      '/suppliers', // Add route for purchase orders
                    ),
                    const SizedBox(height: 20),
                    _buildDrawerMenuItem(
                      context,
                      'Users',
                      "assets/Icons/Navigation bar/order-history-unactive.png",
                      '/users', // Add route for purchase orders
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.05,
              top: MediaQuery.of(context).size.height - 190,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary, // Set the background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Rounded corners
                  ),
                  fixedSize: Size(
                    MediaQuery.of(context).size.width * 0.6,
                    56, // Fixed size
                  ),
                ),
                onPressed: _signOut,
                child: const Center(
                  child: Text(
                    'Log Out',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(
      BuildContext context, String title, String imageUrl, String routeName) {
    return InkWell(
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            child: Image.asset(imageUrl),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353934),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
