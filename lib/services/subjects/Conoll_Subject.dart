class Conoll_Subject {
  final String id;
  String name;
  String teacher;
  List<String> students;
  int grade;
  int room;
  //constructor
  Conoll_Subject({
    required this.id,
    required this.name,
    required this.teacher,
    required this.students,
    required this.grade,
    required this.room,
  });

  factory Conoll_Subject.fromJson(Map<String, dynamic> json) {
    return Conoll_Subject(
      id: (json['id'] == null) ? '' : json['id'].toString(),
      name: json['name']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      students: (json['students'] is List)
          ? (json['students'] as List).map((e) => e?.toString() ?? '').toList()
          : <String>[],
      grade: json['grade'] is int
          ? (json['grade'] as int)
          : (json['grade'] is String
                ? int.tryParse(json['grade'] as String) ?? 0
                : 0),
      room: json['room'] is int
          ? (json['room'] as int)
          : (json['room'] is String
                ? int.tryParse(json['room'] as String) ?? 0
                : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'students': students,
      'grade': grade,
      'room': room,
    };
  }
}
