import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import 'Common/sidebar_component.dart';
import 'Common/user_state.dart';
import 'auth/edit_credentials.dart';
import 'store/store_details.dart';
import '../franchise/franchise_details.dart';
import '../product/product_categories.dart';
import '../product/product_details.dart';
import '../purchase/purchase_all.dart';
import 'others/company_details.dart';
import 'others/dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final theme = FlutterFlowTheme.of(context);
    final userState = Provider.of<UserState>(context);

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
              // physics: const NeverScrollableScrollPhysics(),
              children: [
                const EditCredentialsPage(),
                const DashboardPage(),
                const StoreDetailsPage(),
                const PurchaseOrdersPage(),
                ProductsPage(franchiseID: userState.franchiseID),
                CategoriesPage(franchiseID: userState.franchiseID),
                FranchisePage(franchiseID: userState.franchiseID),
                CompanyDetailsPage(franchiseID: userState.franchiseID),
              ],
            ),
          ),
        ],
      ),
    );
  }
}