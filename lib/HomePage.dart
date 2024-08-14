import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../Common/flutter_flow_theme.dart';
import 'Common/sidebar_component.dart';
import 'Common/user_state.dart';
import 'auth/edit_credentials.dart';
import '../store/store_details.dart';
import '../franchise/franchise_details.dart';
import '../product/product_categories.dart';
import '../product/product_details.dart';
import 'others/company_details.dart';
import 'others/dashboard_page.dart';
import 'purchase/purchase_all.dart';
import 'sales/sales_all.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final PageController pageController = PageController();
  final SideMenuController sideMenuController = SideMenuController();

  @override
  void initState() {
    super.initState();
    sideMenuController.addListener((index) {
      pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

    List<Widget> pages = userState.role == "owner"
        ? [
      const EditCredentialsPage(),
      // const DashboardPage(),
      const StoreDetailsPage(),
      const PurchaseOrdersPage(),
      const SalesOrdersPage(),
      ProductsPage(franchiseID: userState.franchiseID),
      CategoriesPage(franchiseID: userState.franchiseID),
      FranchisePage(franchiseID: userState.franchiseID),
      CompanyDetailsPage(franchiseID: userState.franchiseID),
    ]
        : (userState.role == "staff"
        ? [
      const EditCredentialsPage(),
      const StoreDetailsPage(),
      const PurchaseOrdersPage(),
      const SalesOrdersPage(),
      ProductsPage(franchiseID: userState.franchiseID),
      CategoriesPage(franchiseID: userState.franchiseID),
      FranchisePage(franchiseID: userState.franchiseID),
      CompanyDetailsPage(franchiseID: userState.franchiseID),
    ]
        : [
      const EditCredentialsPage(),
      const SalesOrdersPage(),
    ]);

    if (Platform.isAndroid || Platform.isIOS){
      // Mobile View (iOS/Android)
      return Scaffold(
        appBar: AppBar(
          title: const Text('Franchise Manager'),
          backgroundColor: theme.primaryColor,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: Drawer(
          child: SidebarComponent(sideMenuController: sideMenuController),
        ),
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
      );
    } else {
      // Web/Desktop View
      return Scaffold(
        appBar: AppBar(
          title: const Text('Franchise Manager'),
          backgroundColor: theme.primaryColor,
        ),
        body: Row(
          children: [
            SidebarComponent(sideMenuController: sideMenuController),
            const VerticalDivider(width: 1),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
