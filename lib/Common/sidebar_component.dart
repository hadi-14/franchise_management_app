import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Common/flutter_flow_theme.dart';

class SidebarComponent extends StatefulWidget {
  final SideMenuController sideMenuController;

  const SidebarComponent({super.key, required this.sideMenuController});

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
      final docSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();
      final data = docSnapshot.data();
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
        itemOuterPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      title: _buildUserProfile(theme),
      items: _buildMenuItems(),
    );
  }

  Widget _buildUserProfile(FlutterFlowTheme theme) {
    final user = _auth.currentUser;

    return Column(
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
                  child: user?.photoURL != null
                      ? Image.network(
                          user!.photoURL!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.account_circle,
                          size: 44, color: theme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Guest',
                    style: theme.bodyLarge,
                  ),
                  Text(
                    user?.email ?? '',
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
    );
  }

  List<SideMenuItem> _buildMenuItems() {
    print(_userRole);
    if (_userRole == 'owner') {
      return _buildOwnerMenuItems();
    } else if (_userRole == 'staff') {
      return _buildStaffMenuItems();
    } else if (_userRole == 'franchisee') {
      return _buildFranchiseeMenuItems();
    } else {
      return _buildGuestMenuItems();
    }
  }

  List<SideMenuItem> _buildOwnerMenuItems() {
    return [
      SideMenuItem(
        title: 'User Settings',
        onTap: (index, _) {
          widget.sideMenuController.changePage(0);
        },
        icon: const Icon(Icons.supervised_user_circle_rounded),
      ),
      SideMenuItem(
        title: 'Dashboard',
        onTap: (index, _) {
          widget.sideMenuController.changePage(1);
        },
        icon: const Icon(Icons.space_dashboard),
      ),
      SideMenuItem(
        title: 'Store',
        onTap: (index, _) {
          widget.sideMenuController.changePage(2);
        },
        icon: const Icon(Icons.store),
      ),
      SideMenuItem(
        title: 'Purchase',
        onTap: (index, _) {
          widget.sideMenuController.changePage(3);
        },
        icon: const Icon(Icons.local_grocery_store),
      ),
      SideMenuItem(
        title: 'Sales',
        onTap: (index, _) {
          widget.sideMenuController.changePage(4);
        },
        icon: const Icon(Icons.scale_sharp),
      ),
      SideMenuItem(
        title: 'Products',
        onTap: (index, _) {
          widget.sideMenuController.changePage(5);
        },
        icon: const Icon(Icons.assignment),
      ),
      SideMenuItem(
        title: 'Product Categories',
        onTap: (index, _) {
          widget.sideMenuController.changePage(6);
        },
        icon: const Icon(Icons.category_rounded),
      ),
      SideMenuItem(
        title: 'Franchises',
        onTap: (index, _) {
          widget.sideMenuController.changePage(7);
        },
        icon: const Icon(Icons.cable),
      ),
      SideMenuItem(
        title: 'Company Details',
        onTap: (index, _) {
          widget.sideMenuController.changePage(8);
        },
        icon: const Icon(Icons.grid_on_rounded),
      ),
    ];
  }

  List<SideMenuItem> _buildStaffMenuItems() {
    return [
      SideMenuItem(
        title: 'User Settings',
        onTap: (index, _) {
          widget.sideMenuController.changePage(0);
        },
        icon: const Icon(Icons.supervised_user_circle_rounded),
      ),
      SideMenuItem(
        title: 'Store',
        onTap: (index, _) {
          widget.sideMenuController.changePage(1);
        },
        icon: const Icon(Icons.store),
      ),
      SideMenuItem(
        title: 'Purchase',
        onTap: (index, _) {
          widget.sideMenuController.changePage(2);
        },
        icon: const Icon(Icons.local_grocery_store),
      ),
      SideMenuItem(
        title: 'Sales',
        onTap: (index, _) {
          widget.sideMenuController.changePage(3);
        },
        icon: const Icon(Icons.scale_sharp),
      ),
      SideMenuItem(
        title: 'Products',
        onTap: (index, _) {
          widget.sideMenuController.changePage(4);
        },
        icon: const Icon(Icons.assignment),
      ),
      SideMenuItem(
        title: 'Product Categories',
        onTap: (index, _) {
          widget.sideMenuController.changePage(5);
        },
        icon: const Icon(Icons.category_rounded),
      ),
    ];
  }

  List<SideMenuItem> _buildFranchiseeMenuItems() {
    return [
      SideMenuItem(
        title: 'User Settings',
        onTap: (index, _) {
          widget.sideMenuController.changePage(0);
        },
        icon: const Icon(Icons.supervised_user_circle_rounded),
      ),
      SideMenuItem(
        title: 'Purchase',
        onTap: (index, _) {
          widget.sideMenuController.changePage(1);
        },
        icon: const Icon(Icons.local_grocery_store),
      ),
    ];
  }

  List<SideMenuItem> _buildGuestMenuItems() {
    return [
      SideMenuItem(
        title: 'User Settings',
        onTap: (index, _) {
          widget.sideMenuController.changePage(0);
        },
        icon: const Icon(Icons.supervised_user_circle_rounded),
      ),
    ];
  }
}
