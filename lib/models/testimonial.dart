import 'package:cloud_firestore/cloud_firestore.dart';

class Testimonial {
  final String id;
  final String name;
  final String content;
  final int rating;
  final String status; // 'pending', 'approved'
  final DateTime createdAt;

  Testimonial({
    required this.id,
    required this.name,
    required this.content,
    required this.rating,
    required this.status,
    required this.createdAt,
  });

  factory Testimonial.fromFirestore(Map<String, dynamic> data, String id) {
    return Testimonial(
      id: id,
      name: data['name'] ?? '',
      content: data['text'] ?? data['message'] ?? '', // Support both field names
      rating: data['rating'] ?? 5,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
