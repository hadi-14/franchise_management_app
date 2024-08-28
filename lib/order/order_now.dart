import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../Common/drawer.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import '../product/add_products.dart';
import '../product/product_categories.dart';
import '../product/product_detail_view.dart';
import 'package:change_case/change_case.dart';

class OrderNowFranchisePage extends StatefulWidget {
  final String franchiseID;

  const OrderNowFranchisePage({super.key, required this.franchiseID});

  @override
  _OrderNowFranchisePageState createState() => _OrderNowFranchisePageState();
}

class _OrderNowFranchisePageState extends State<OrderNowFranchisePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategoryID;
  Map<String, String> _categories = {};
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(() {
      setState(() {}); // Update the UI when the search text changes
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    if (widget.franchiseID.isEmpty) return;

    final snapshot = await _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('category')
        .get();

    setState(() {
      _categories = {
        for (var doc in snapshot.docs) doc.id: doc['name'] as String,
      };
    });
  }

  Future<List<DocumentSnapshot>> _fetchProducts() async {
    Query query = _firestore
        .collection('product')
        .doc(widget.franchiseID)
        .collection('list');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      query = query
          .where('productName',
              isGreaterThanOrEqualTo: _searchController.text.toCapitalCase())
          .where('productName',
              isLessThanOrEqualTo:
                  '${_searchController.text.toCapitalCase()}\uf8ff');
    }

    // Apply category filter
    if (_selectedCategoryID != null) {
      query = query.where('categoryID', isEqualTo: _selectedCategoryID);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);

    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            !(userState.role == 'owner' || userState.role == 'staff')
                ? Container(
                    width: screenWidth * 0.6,
                    height: 30,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            width: 1, color: Color(0x70D1A784)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 7.0, top: 5.0),
                      child: Text(
                        'Franchise ID: ${userState.franchiseInternalID}',
                        style: const TextStyle(
                          color: Color(0xFF552E05),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: screenWidth * 0.6,
                    height: 30,
                    child: Text(userState.company ?? '', style: theme.labelSmall),
                  ),
            SizedBox(width: screenWidth * 0.06),
            SizedBox(
              width: 30,
              height: 30,
              child: Image.network(userState.profilePhoto),
            ),
          ],
        ),
      ),
      drawer: DrawerWidget(), // Drawer added here
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 20.0,
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                ),
                child: Container(
                  width: screenWidth * 0.9,
                  height: 45,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x26686868),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: Icon(Icons.search),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF552E05),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_categories.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: 20.0,
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategoryID,
                    hint: const Text('Select Category'),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12.0),
                    items: _categories.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryID = value;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<DocumentSnapshot>>(
                  future: _fetchProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }

                    return _buildCardLayout(data, theme);
                  },
                ),
              ),
            ],
          ),
          _buildOverlayOptions(theme),
        ],
      ),
      floatingActionButton:
          (userState.role == 'owner' || userState.role == 'staff')
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 70.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_isExpanded) {
                        _animationController.reverse();
                      } else {
                        _animationController.forward();
                      }
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    backgroundColor: theme.primary,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              : null, // Show FAB only if user is 'owner' or 'staff'
    );
  }

  Widget _buildCardLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600
            ? 3
            : 2, // Adjusts the number of columns based on screen width
        crossAxisSpacing: 10,
        mainAxisSpacing: 2,
        childAspectRatio: MediaQuery.of(context).size.width > 600
            ? 0.8
            : 0.7, // Adjusts the aspect ratio based on screen width
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final product = data[index].data() as Map<String, dynamic>;
        product['ID'] = data[index].id;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product)),
            );
          },
          child: SizedBox(
            width: 250,
            height: 181,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Image.network(
                    width: 250,
                    height: 135,
                    product['image'] ?? "https://via.placeholder.com/250x135",
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 135,
                  child: Container(
                    width: 250,
                    height: 66,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['productName'],
                          style: theme.bodyLarge,
                        ),
                        Text(
                          '\$ ${product['price']}',
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.primary,
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
      },
    );
  }

  Widget _buildOverlayOptions(FlutterFlowTheme theme) {
    return Positioned(
      bottom: 160,
      right: 16,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'addProduct',
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                  _animationController.reverse();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddProducts(),
                    ),
                  );
                },
                backgroundColor: theme.primaryBackground,
                child: Icon(Icons.add_shopping_cart, color: theme.primaryText),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'addCategory',
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                  _animationController.reverse();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoryPage(),
                    ),
                  );
                },
                backgroundColor: theme.primaryBackground,
                child: Icon(Icons.category, color: theme.primaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
