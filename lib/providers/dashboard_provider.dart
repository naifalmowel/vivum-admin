import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider with ChangeNotifier {
  int? _projectCount;
  int? _messageCount;
  int? _userCount;
  List<Map<String, dynamic>>? _recentMessages;
  
  StreamSubscription? _projSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _userSub;
  StreamSubscription? _recentMsgSub;

  int get projectCount => _projectCount ?? 0;
  int get messageCount => _messageCount ?? 0;
  int get userCount => _userCount ?? 0;
  List<Map<String, dynamic>> get recentMessages => _recentMessages ?? [];

  bool get isLoading => _projectCount == null || _messageCount == null || _userCount == null || _recentMessages == null;

  DashboardProvider() {
    _init();
  }

  void _init() {
    _projSub = FirebaseFirestore.instance.collection('projects').snapshots().listen((snap) {
      _projectCount = snap.docs.length;
      notifyListeners();
    });

    _msgSub = FirebaseFirestore.instance.collection('contact_requests').snapshots().listen((snap) {
      _messageCount = snap.docs.length;
      notifyListeners();
    });

    _userSub = FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
      _userCount = snap.docs.length;
      notifyListeners();
    });

    _recentMsgSub = FirebaseFirestore.instance
        .collection('contact_requests')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .listen((snap) {
      _recentMessages = snap.docs.map((d) => d.data()).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _msgSub?.cancel();
    _userSub?.cancel();
    _recentMsgSub?.cancel();
    super.dispose();
  }
}
