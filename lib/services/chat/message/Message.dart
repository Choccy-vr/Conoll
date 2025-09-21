class Message {
  int id;
  DateTime timestamp;
  String content;
  String senderId;
  String room;

  Message({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.senderId,
    required this.room,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String,
      senderId: json['user'] as String,
      room: json['room'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_at': timestamp.toIso8601String(),
      'content': content,
      'user': senderId,
      'room': room,
    };
  }
}
