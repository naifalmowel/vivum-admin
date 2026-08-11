import 'package:cloud_firestore/cloud_firestore.dart';

class ContactRequest {
  final String id;
  final String name;
  final String email;
  final String phone; // Added phone
  final String company;
  final String service;
  final String message;
  final DateTime createdAt;
  final bool isRead;    // Added read status
  final bool isReplied; // Added replied status

  ContactRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.service,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.isReplied = false,
  });

  factory ContactRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return ContactRequest(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      company: data['company'] ?? '',
      service: data['service'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isReplied: data['isReplied'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'service': service,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
      'isReplied': isReplied,
    };
  }
}
