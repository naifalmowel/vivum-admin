class ContactRequest {
  final String id;
  final String name;
  final String email;
  final String message;
  final DateTime timestamp;

  ContactRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.timestamp,
  });

  factory ContactRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return ContactRequest(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
