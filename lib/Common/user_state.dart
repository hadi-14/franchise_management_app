import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserState with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _franchiseID = '';

  User? get user => _user;
  String get franchiseID => _franchiseID;

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
      final docSnapshot = await _firestore.collection('user').doc(_user!.uid).get();
      final data = docSnapshot.data();
      _franchiseID = data?['franchiseID'] ?? '';
      notifyListeners();
    }
  }
}
