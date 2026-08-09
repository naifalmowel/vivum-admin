class Project {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  Project({required this.id, required this.name, required this.description, required this.imageUrl});

  factory Project.fromFirestore(Map<String, dynamic> data, String id) {
    return Project(
      id: id,
      name: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
