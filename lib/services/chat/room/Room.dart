class Room {
  final String id;
  final DateTime createdAt;
  final RoomType room_type;
  final String name;
  final List<String> members;

  Room({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.room_type,
    required this.members,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      room_type: RoomType.values.byName(json['room_type'] as String),
      members: List<String>.from(json['members'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'room_type': room_type.name,
      'members': members,
    };
  }
}

enum RoomType { direct, group, classRoom, subject, grade }
