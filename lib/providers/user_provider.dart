import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  StreamSubscription? _userSub;

  UserProvider() {
    _init();
  }

  String get userName => _userName.isEmpty ? (FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Admin') : _userName;

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user != null) {
        _userSub = FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .snapshots()
            .listen((snap) {
          if (snap.docs.isNotEmpty) {
            _userName = snap.docs.first.get('name') ?? '';
            notifyListeners();
          }
        });
      } else {
        _userName = '';
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
