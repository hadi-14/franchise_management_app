import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import 'auth/user_setting.dart';
import 'order/order_checkout.dart';
import 'order/order_history.dart';
import 'order/order_now.dart';
import 'order/order_status.dart';
import '../scanner/scanner.dart'; // Import the Scanner page

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    final userState = Provider.of<UserState>(context, listen: false);
    final isOwnerOrStaff = userState.role == 'owner' || userState.role == 'staff';

    // Initialize TabController with dynamic length based on role
    tabController = TabController(
      length: isOwnerOrStaff ? 4 : 5, // Set length dynamically
      vsync: this,
    );

    currentPage = 0;
    tabController.animation!.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        changePage(value);
      }
    });
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);
    final bool isOwnerOrStaff = userState.role == 'owner' || userState.role == 'staff';

    // Define pages and tabs based on user role
    List<List<Widget>> element = _getPagesForUserRole(userState, theme);
    List<Widget> pages = element.first;
    List<Widget> tabs = element.last;

    const Color unselectedColor = Colors.grey;

    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isOwnerOrStaff
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      // Navigate to the scanner page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BarcodeScannerWithZoom()),
                      );
                    },
                    backgroundColor: theme.primary,
                    shape: const CircleBorder(),
                    child: Icon(
                      Icons.qr_code_scanner, // Use scan icon
                      color: theme.tertiary,
                      size: 28, // Adjust the size as needed
                    ),
                  ),
                )
              : Container(),
          body: BottomBar(
            fit: StackFit.expand,
            icon: (width, height) => Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: null,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: unselectedColor,
                  size: width,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(500),
            duration: const Duration(seconds: 1),
            curve: Curves.decelerate,
            showIcon: true,
            width: MediaQuery.of(context).size.width * 0.8,
            barColor: theme.secondary,
            start: 2,
            end: 0,
            offset: 10,
            barAlignment: Alignment.bottomCenter,
            iconHeight: 35,
            iconWidth: 35,
            reverse: false,
            hideOnScroll: true,
            scrollOpposite: false,
            onBottomBarHidden: () {},
            onBottomBarShown: () {},
            body: (context, controller) => TabBarView(
              controller: tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: pages,
            ),
            child: TabBar(
              controller: tabController,
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: theme.primary,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              tabs: tabs,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabIcon(String iconData, int index, FlutterFlowTheme theme) {
    return SizedBox(
      height: 55,
      width: 40,
      child: Center(
        child: Image.asset(
          iconData,
          width: 20,
          fit: BoxFit.fitWidth,
          color: currentPage == index
              ? theme.secondaryBackground
              : const Color.fromARGB(128, 255, 255, 255),
        ),
      ),
    );
  }

  List<List<Widget>> _getPagesForUserRole(
      UserState userState, FlutterFlowTheme theme) {
    if (userState.role == 'owner' || userState.role == 'staff') {
      return [
        [
          OrderNowFranchisePage(franchiseID: userState.franchiseID),
          OrderHistoryPage(),
          const BarcodeScannerWithZoom(),
          const OrderStatusPage(),
          const UserSetting()
        ],
        [
          _buildTabIcon("assets/Icons/Navigation bar/shop.png", 0, theme),
          _buildTabIcon(
              "assets/Icons/Navigation bar/order-history.png", 1, theme),
          const SizedBox(width: 40), // Empty space for the FAB in the center
          _buildTabIcon("assets/Icons/Navigation bar/box-open.png", 3, theme),
          _buildTabIcon("assets/Icons/Navigation bar/settings.png", 4, theme),
        ]
      ];
    } else {
      return [
        [
          OrderNowFranchisePage(franchiseID: userState.franchiseID),
          CheckoutCart(tabController: tabController),
          const OrderStatusPage(),
          const UserSetting()
        ],
        [
          _buildTabIcon("assets/Icons/Navigation bar/shop.png", 0, theme),
          _buildTabIcon(
              "assets/Icons/Navigation bar/order-history.png", 1, theme),
          _buildTabIcon("assets/Icons/Navigation bar/box-open.png", 2, theme),
          _buildTabIcon("assets/Icons/Navigation bar/settings.png", 3, theme),
        ]
      ];
    }
  }
}
