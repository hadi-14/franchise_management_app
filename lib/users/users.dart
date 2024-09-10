import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';
import '../.env.dart'; // Assuming kApiUrl is defined here

class FranchiseAndStaffEntry extends StatefulWidget {
  const FranchiseAndStaffEntry({Key? key}) : super(key: key);

  @override
  _FranchiseAndStaffEntryState createState() => _FranchiseAndStaffEntryState();
}

class _FranchiseAndStaffEntryState extends State<FranchiseAndStaffEntry>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedRole;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Fetch users based on role and franchiseID from Firestore, including documentID as uid
  Future<List<Map<String, dynamic>>> _fetchUsers(
      String role, String franchiseID) async {
    QuerySnapshot snapshot = await _firestore
        .collection('user')
        .where('franchiseID', isEqualTo: franchiseID)
        .where('role', isEqualTo: role)
        .get();

    // Include uid from document ID and map other data
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id; // Assign documentID as uid
      return data;
    }).toList();
  }

  // Function to generate franchise internal ID (if needed)
  Future<String> _generateFranchiseInternalID(String franchiseID) async {
    QuerySnapshot snapshot = await _firestore
        .collection('user')
        .where('franchiseID', isEqualTo: franchiseID)
        .where('role', isEqualTo: 'franchisee')
        .get();

    // Assign an incremental internal ID based on the number of franchisees
    return "${franchiseID}_${snapshot.size + 1}";
  }

  // Function to show the popup dialog to add a user
  void _showAddUserDialog(String franchiseID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Invite User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['Franchisee', 'Staff'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text.trim();

                if (email.isNotEmpty && selectedRole != null) {
                  String franchiseInternalID = selectedRole == 'Franchisee'
                      ? await _generateFranchiseInternalID(franchiseID)
                      : '';

                  _saveUser(email, selectedRole!, franchiseID, franchiseInternalID);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to save the email, role, and franchiseInternalID in Firestore
  Future<void> _saveUser(String email, String role, String franchiseID, String franchiseInternalID) async {
    try {
      await _firestore.collection('user').add({
        'email': email,
        'role': role,
        'franchiseID': franchiseID,
        if (role == 'Franchisee') 'franchiseInternalID': franchiseInternalID,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final theme = FlutterFlowTheme.of(context);

    // Get the franchiseID from UserState
    final userState = Provider.of<UserState>(context, listen: false);
    final String franchiseID =
        userState.franchiseID; // Assuming franchiseID is stored in UserState

    return Scaffold(
      appBar: AppBar(
        title: const Text('Franchise and Staff'),
        centerTitle: true,
        backgroundColor: const Color(0xFFB5733B),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: "Franchisee"),
            Tab(text: "Staff"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(context, screenWidth, screenHeight, "franchisee",
                    franchiseID),
                _buildUserList(
                    context, screenWidth, screenHeight, "staff", franchiseID),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show the popup dialog to add a user
          _showAddUserDialog(franchiseID);
        },
        backgroundColor: const Color(0xFFB5733B),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Fetch additional user details (email and displayName) from API
  Future<Map<String, dynamic>> _fetchUserDetailsFromAPI(String uid) async {
    try {
      final response =
          await http.get(Uri.parse('$kApiUrl/user-details?uid=$uid'));
      if (response.statusCode == 200) {
        final serverData = jsonDecode(response.body);
        return {
          'email': serverData['email'] ?? 'N/A',
          'displayName': serverData['displayName'] ?? 'N/A',
        };
      } else {
        return {
          'email': 'Error',
          'displayName': 'Error',
        };
      }
    } catch (e) {
      return {
        'email': 'Error',
        'displayName': 'Error',
      };
    }
  }


  // Common user list (for Franchisee or Staff based on role and franchiseID)
  Widget _buildUserList(BuildContext context, double screenWidth,
      double screenHeight, String role, String franchiseID) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUsers(role, franchiseID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        // Filter users based on the search query with null checking
        final filteredUsers = users
            .where((user) => (user['email'] ?? '')
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
            child: Column(
              children: filteredUsers.map((user) {
                final uid =
                    user['uid'] ?? ''; // Now we ensure uid is from document ID
                return FutureBuilder<Map<String, dynamic>>(
                  future: _fetchUserDetailsFromAPI(uid),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${userSnapshot.error}'));
                    }

                    final userDetails = userSnapshot.data ??
                        {'email': 'N/A', 'displayName': 'N/A'};
                    return _buildUserCard(
                        context,
                        screenWidth,
                        userDetails['displayName'] ?? 'Unknown',
                        userDetails['email'] ?? 'No email',
                        user['franchiseInternalID'] ?? 'N/A',
                        user['phoneNumber'] ?? 'No phone',
                        user['Address'] ?? {});
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // User Card Widget with data from Firestore and API
  Widget _buildUserCard(
      BuildContext context,
      double screenWidth,
      String displayName,
      String email,
      String franchiseInternalID,
      String phoneNumber,
      Map<String, dynamic> address) {
    return Container(
      width: screenWidth * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName, // Use the API user's display name
                style: const TextStyle(
                  color: Color(0xFF353934),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'ID: $franchiseInternalID', // Default value if 'franchiseInternalID' is not available
                style: const TextStyle(
                  color: Color(0xFF8E918D),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email, // Use the API user's email
            style: const TextStyle(
              color: Color(0xFF353934),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phoneNumber, // Default value if 'phoneNumber' is not available
            style: const TextStyle(
              color: Color(0xFF353934),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF552E05)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${address['street'] ?? 'N/A'}, ${address['city'] ?? 'N/A'}, ${address['state'] ?? 'N/A'}, ${address['country'] ?? 'N/A'}, ${address['zip'] ?? 'N/A'}",
                  style: const TextStyle(
                    color: Color(0xFF8E918D),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search Box Widget with real-time search functionality
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
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
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Color(0xFF552E05)),
            hintText: 'Search...',
          ),
          onChanged: (query) {
            setState(() {
              searchQuery = query;
            });
          },
        ),
      ),
    );
  }
}
