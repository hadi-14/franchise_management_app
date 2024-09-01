import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for Firebase Storage
import 'package:provider/provider.dart';
import '../Common/drawer.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import '../product/add_products.dart';
import '../product/product_categories.dart';
import '../product/product_detail_view.dart';
import 'package:change_case/change_case.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrderNowFranchisePage extends StatefulWidget {
  final String franchiseID;

  const OrderNowFranchisePage({super.key, required this.franchiseID});

  @override
  _OrderNowFranchisePageState createState() => _OrderNowFranchisePageState();
}

class _OrderNowFranchisePageState extends State<OrderNowFranchisePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance
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

  Future<String> _fetchImageFromStorage(String imageRef) async {
    try {
      return await _storage.refFromURL(imageRef).getDownloadURL();
    } catch (e) {
      print('Error fetching image from storage: $e');
      return "https://via.placeholder.com/250x135"; // Fallback to a placeholder if fetching fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);

    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

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
                : !(userState.role == 'franchisee')
                    ? SizedBox(
                        width: screenWidth * 0.6,
                        height: 30,
                        child: Center(
                          child: Text(userState.company ?? '',
                              style: const TextStyle(
                                color: Color(0xFF552E05),
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              )),
                        ),
                      )
                    : SizedBox(
                        width: screenWidth * 0.6,
                        height: 30,
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
                  child: Frame313659(
                    categories: _categories,
                    selectedCategoryID: _selectedCategoryID,
                    onCategorySelected: (String categoryID) {
                      setState(() {
                        _selectedCategoryID = categoryID;
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

                    return _buildCardLayout(data, theme, userState);
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
                      // Toggle animation without calling setState
                      if (_isExpanded) {
                        _animationController.reverse();
                      } else {
                        _animationController.forward();
                      }
                      _isExpanded = !_isExpanded;
                    },
                    backgroundColor: theme.primary,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              : null, // Show FAB only if user is 'owner' or 'staff'
    );
  }

  Widget _buildCardLayout(List<DocumentSnapshot> data, FlutterFlowTheme theme,
      UserState userState) {
    double containerWidth = (MediaQuery.of(context).size.width - 60) / 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 75.0),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 2,
          childAspectRatio: 0.65,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final product = data[index].data() as Map<String, dynamic>;
          product['ID'] = data[index].id;

          return FutureBuilder<String>(
            future: _fetchImageFromStorage(product['image'] ?? ''),
            builder: (context, snapshot) {
              String imageUrl =
                  product['image'] ?? "https://via.placeholder.com/250x135";
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                imageUrl = snapshot.data!;
              }
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsPage(product: product)),
                  );
                },
                child: SizedBox(
                  width: containerWidth,
                  height:
                      (userState.role == 'owner' || userState.role == 'staff')
                          ? 246
                          : 224, // Increased height to accommodate more content
                  child: Stack(
                    children: [
                      // Card background
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: containerWidth,
                          height: (userState.role == 'owner' ||
                                  userState.role == 'staff')
                              ? 246
                              : 224, // Increased height to match container
                          decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26686868),
                                blurRadius: 8,
                                offset: Offset(0, 1),
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Product Image
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Image.network(
                          width: containerWidth,
                          height: 135,
                          imageUrl,
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Product details and price alignment
                      Positioned(
                        left: 0,
                        top: 140, // Adjusted top position for added padding
                        child: Stack(
                          children: [
                            Container(
                              width: containerWidth,
                              height: (userState.role == 'owner' ||
                                      userState.role == 'staff')
                                  ? 106
                                  : 84, // Adjusted top position for added padding
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 10),
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
                                    style: theme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$ ${product['price']}',
                                    style: theme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (userState.role == 'owner' ||
                                      userState.role == 'staff')
                                    Text(
                                      'Quantity: ${product['quantity']}',
                                      style: theme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: theme.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Edit button for owner or staff
                            if (userState.role == 'owner' ||
                                userState.role == 'staff')
                              Positioned(
                                left: containerWidth - 60,
                                bottom: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      4.0), // Bigger hitbox
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: SvgPicture.asset(
                                        'assets/Icons/edit.svg',
                                        semanticsLabel: 'Edit Logo'),
                                    onPressed: () async {
                                      final shouldRefresh =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddProducts(productData: product),
                                        ),
                                      );

                                      if (shouldRefresh == true) {
                                        setState(() {}); // Reload the page
                                      }
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'addProduct',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddProducts(),
                    ),
                  );
                },
                backgroundColor: theme.primaryBackground,
                shape: const CircleBorder(),
                mini: true,
                child: Icon(
                  Icons.add_shopping_cart,
                  color: theme.secondaryText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 5),
              FloatingActionButton(
                heroTag: 'addCategory',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoryPage(),
                    ),
                  );
                },
                backgroundColor: theme.primaryBackground,
                shape: const CircleBorder(),
                mini: true,
                child: Icon(
                  Icons.category,
                  color: theme.secondaryText,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Frame313659 extends StatelessWidget {
  final Map<String, String> categories;
  final String? selectedCategoryID;
  final ValueChanged<String> onCategorySelected;

  const Frame313659({
    required this.categories,
    required this.selectedCategoryID,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.entries.map((entry) {
          final isSelected = entry.key == selectedCategoryID;
          return GestureDetector(
            onTap: () => onCategorySelected(entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFD09A6C) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF876A51)),
              ),
              child: Text(
                entry.value,
                style: theme.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF353934),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
