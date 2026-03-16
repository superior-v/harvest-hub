class Post {
  String id;
  String title;
  String description;
  String location;
  String contact;
  String userId;

  Post({
    this.id = "",
    required this.title,
    required this.description,
    required this.location,
    required this.contact,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'contact': contact,
      'userId': userId,
    };
  }

  static Post fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      title: data['title'],
      description: data['description'],
      location: data['location'],
      contact: data['contact'],
      userId: data['userId'],
    );
  }
}
