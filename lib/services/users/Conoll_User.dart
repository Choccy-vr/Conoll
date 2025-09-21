class Conoll_User {
  //identifiers
  final String id;
  String name;
  String username;
  String handle;
  //Time
  final DateTime createdAt;
  DateTime updatedAt;
  //School
  int grade;
  List<String> classes;
  //constructor
  Conoll_User({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    required this.grade,
    required this.classes,
    required this.handle,
  });

  factory Conoll_User.fromJson(Map<String, dynamic> json) {
    return Conoll_User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      grade: json['grade'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      classes: List<String>.from(json['classes'] ?? []),
      handle: json['handle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'grade': grade,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'classes': classes,
      'handle': handle,
    };
  }
}
