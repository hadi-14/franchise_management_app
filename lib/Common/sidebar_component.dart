import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Common/flutter_flow_theme.dart';

class SidebarComponent extends StatefulWidget {
  final SideMenuController sideMenuController;

  const SidebarComponent({Key? key, required this.sideMenuController})
      : super(key: key);

  @override
  _SidebarComponentState createState() => _SidebarComponentState();
}

class _SidebarComponentState extends State<SidebarComponent> {
  bool isDarkMode = false;
  final _auth = FirebaseAuth.instance;
  String _userRole = 'guest';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
      final data = docSnapshot.data() as Map<String, dynamic>?;
      setState(() {
        _userRole = data?['role'] ?? 'guest';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selectedColor = theme.primary;

    return SideMenu(
      controller: widget.sideMenuController,
      style: SideMenuStyle(
        displayMode: SideMenuDisplayMode.auto,
        hoverColor: theme.secondaryBackground,
        selectedColor: selectedColor,
        unselectedTitleTextStyle: theme.bodyMedium,
        unselectedIconColor: theme.secondaryText,
        selectedTitleTextStyle: theme.bodyMedium.override(
          fontFamily: 'Readex Pro',
          color: theme.primaryText,
          letterSpacing: 0.0,
        ),
        selectedIconColor: theme.primaryText,
        itemBorderRadius: BorderRadius.circular(10),
        itemOuterPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      title: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.accent1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.primary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _auth.currentUser!.photoURL!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auth.currentUser!.displayName!,
                      style: theme.bodyLarge,
                    ),
                    Text(
                      _auth.currentUser!.email!,
                      style: theme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 12.0,
            thickness: 2.0,
            color: theme.alternate,
          ),
        ],
      ),
      items: _buildMenuItems(),
    );
  }

  List<SideMenuItem> _buildMenuItems() {
    final List<SideMenuItem> menuItems = [
      SideMenuItem(
        title: 'Dashboard',
        onTap: (index, _) {
          widget.sideMenuController.changePage(0);
        },
        icon: const Icon(Icons.space_dashboard),
      ),
    ];

    if (_userRole == 'staff' || _userRole == 'owner') {
      menuItems.addAll([
        SideMenuItem(
          title: 'Store',
          onTap: (index, _) {
            widget.sideMenuController.changePage(1);
          },
          icon: const Icon(Icons.store),
        ),
        SideMenuItem(
          title: 'Inventory',
          onTap: (index, _) {
            widget.sideMenuController.changePage(2);
          },
          icon: const Icon(Icons.local_grocery_store),
        ),
        SideMenuItem(
          title: 'Products',
          onTap: (index, _) {
            widget.sideMenuController.changePage(3);
          },
          icon: const Icon(Icons.assignment),
        ),
        SideMenuItem(
          title: 'Product Categories',
          onTap: (index, _) {
            widget.sideMenuController.changePage(4);
          },
          icon: const Icon(Icons.category_rounded),
        ),
      ]);
    }

    if (_userRole == 'owner') {
      menuItems.addAll([
        SideMenuItem(
          title: 'Franchises',
          onTap: (index, _) {
            widget.sideMenuController.changePage(5);
          },
          icon: const Icon(Icons.cable),
        ),
        SideMenuItem(
          title: 'Company Details',
          onTap: (index, _) {
            widget.sideMenuController.changePage(6);
          },
          icon: const Icon(Icons.grid_on_rounded),
        ),
      ]);
    }

    return menuItems;
  }
}
