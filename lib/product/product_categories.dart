import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: theme.primary,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryHeader(context),
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26686868),
              blurRadius: 8,
              offset: Offset(0, 1),
              spreadRadius: 3,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Color(0xFF552E05)),
          ),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild to filter the list
          },
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              color: Color(0xFF353934),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showAddOrEditCategoryDialog(context);
            },
            child: const Text(
              '+ Add Category',
              style: TextStyle(
                color: Color(0xFFD09A6C),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final userState = Provider.of<UserState>(context);

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('product')
            .doc(userState.franchiseID)
            .collection('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching categories'));
          }

          final categories = snapshot.data!.docs;
          final filteredCategories = categories.where((doc) {
            final categoryName = doc['name'].toString().toLowerCase();
            final searchText = _searchController.text.toLowerCase();
            return categoryName.contains(searchText);
          }).toList();

          if (filteredCategories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              return _buildCategoryItem(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(QueryDocumentSnapshot category) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Name: ${category['name']}',
            style: const TextStyle(
              color: Color(0xFF353934),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFD09A6C)),
                onPressed: () {
                  _showAddOrEditCategoryDialog(
                    context,
                    categoryId: category.id,
                    existingName: category['name'],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFD09A6C)),
                onPressed: () {
                  _deleteCategory(category.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditCategoryDialog(BuildContext context,
      {String? categoryId, String? existingName}) async {
    final theme = FlutterFlowTheme.of(context);
    final TextEditingController categoryNameController =
        TextEditingController(text: existingName);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: 300,
            height: 245,
            decoration: BoxDecoration(
              color: const Color(0xFF876A51),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 261,
                  top: 17,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              NetworkImage("https://via.placeholder.com/20x20"),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 26,
                  top: 41,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 247,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1E000000),
                              blurRadius: 15,
                              offset: Offset(0, 10),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: TextField(
                            controller: categoryNameController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write the category name',
                              hintStyle: TextStyle(
                                color: Color(0xFF8E918D),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          if (categoryId == null) {
                            _addCategory(categoryNameController.text);
                          } else {
                            _editCategory(categoryId, categoryNameController.text);
                          }
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 175,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCategory(String categoryName) async {
    final userState = Provider.of<UserState>(context, listen: false);
    if (categoryName.isNotEmpty) {
      await _firestore
          .collection('product')
          .doc(userState.franchiseID)
          .collection('category')
          .add({'name': categoryName});
    }
  }

  Future<void> _editCategory(String categoryId, String categoryName) async {
    final userState = Provider.of<UserState>(context, listen: false);
    if (categoryName.isNotEmpty) {
      await _firestore
          .collection('product')
          .doc(userState.franchiseID)
          .collection('category')
          .doc(categoryId)
          .update({'name': categoryName});
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final userState = Provider.of<UserState>(context, listen: false);
    await _firestore
        .collection('product')
        .doc(userState.franchiseID)
        .collection('category')
        .doc(categoryId)
        .delete();
  }
}
