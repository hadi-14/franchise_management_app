import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserState with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _franchiseID = '';
  String _franchiseInternalID = '';
  String _role = '';
  String _phoneNumber = '';
  String _company = '';
  String? _customerID;
  Map<String, dynamic> _address = {};

  User? get user => _user;
  String get franchiseID => _franchiseID;
  String get franchiseInternalID => _franchiseInternalID;
  String get role => _role;
  Map<String, dynamic> get address => _address;
  String get userName => _auth.currentUser?.displayName ?? 'Guest'; // Safe access
  String get profilePhoto => _auth.currentUser?.photoURL ?? 'https://via.placeholder.com/150'; // Safe access with default
  String get email => _auth.currentUser?.email ?? 'No email'; // Safe access with default
  String? get customerID => _customerID;
  String? get phoneNumber => _phoneNumber;
  String? get company => _company;

  UserState() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (_user != null) {
      await _fetchFranchiseID();
    }
    notifyListeners();
  }

  Future<void> _fetchFranchiseID() async {
    if (_user != null) {
      final docSnapshot =
          await _firestore.collection('user').doc(_user!.uid).get();
      final data = docSnapshot.data();
      _franchiseID = data?['franchiseID'] ?? '';
      _role = data?['role'] ?? '';
      _customerID = data?['customerID'] ?? '';
      _address = data?['Address'] ?? {};
      _franchiseInternalID = data?['franchiseInternalID'] ?? '';
      _phoneNumber = data?['phoneNumber'] ?? '';
      _company = data?['Company'] ?? '';
      notifyListeners();
    }
  }

  // Made this method public by removing the leading underscore
  Future<void> setUserData(String key, dynamic data) async {
    if (_user != null) {
      await _firestore.collection('user').doc(_user!.uid).update({key: data});
    }
  }
}
