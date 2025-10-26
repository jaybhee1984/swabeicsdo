import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  User? firebaseUser;
  Map<String, dynamic>? userProfile;

  bool get isLoggedIn => firebaseUser != null;
  String get employeeNumber => userProfile?['employee_number'] ?? '';
  String get role => userProfile?['role'] ?? '';

  AuthProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      firebaseUser = user;
      if (user != null) {
        await _fetchUserProfile(user.uid);
      } else {
        userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        userProfile = doc.data();
        debugPrint('✅ User profile loaded: $userProfile');
      } else {
        debugPrint('❌ No user profile found for UID: $uid');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
    }
  }

  Future<void> loadUserProfile() async {
    if (firebaseUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .get();
      if (doc.exists) {
        userProfile = doc.data();
        debugPrint('✅ User profile refreshed: $userProfile');
        notifyListeners();
      } else {
        debugPrint('❌ No user profile found for UID: ${firebaseUser!.uid}');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing user profile: $e');
    }
  }

  Future<void> updateEmployeeNumber(String employeeNumber) async {
    if (firebaseUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .set({'employee_number': employeeNumber}, SetOptions(merge: true));
      userProfile?['employee_number'] = employeeNumber;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating employee number: $e');
    }
  }

  /// ✅ Multi-login prevention logic
  Future<void> signIn(String email, String password) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = result.user;

      // Check if user is already active
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .get();

      if (doc.exists && doc.data()?['is_active'] == true) {
        debugPrint('❌ User already logged in elsewhere.');
        await FirebaseAuth.instance.signOut();
        firebaseUser = null;
        userProfile = null;
        notifyListeners();
        return;
      }

      // Mark user as active
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .set({
            'is_active': true,
            'last_login': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _fetchUserProfile(firebaseUser!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
    }
  }

  /// ✅ Logout and mark session inactive
  Future<void> signOut() async {
    if (firebaseUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update({'is_active': false});
    }
    await FirebaseAuth.instance.signOut();
    firebaseUser = null;
    userProfile = null;
    notifyListeners();
  }
}
