import 'dart:convert';

class Conoll_Class {
  final int id;
  int period;
  List<String> students;
  int subjectId;
  int room;
  //constructor
  Conoll_Class({
    required this.id,
    required this.period,
    required this.students,
    required this.subjectId,
    required this.room,
  });

  factory Conoll_Class.fromJson(Map<String, dynamic> json) {
    // Parse students robustly: list of strings, JSON string, comma-separated string, or null
    List<String> parseStudents(dynamic value) {
      if (value == null) return <String>[];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').toList();
      }
      if (value is String) {
        final s = value.trim();
        if (s.isEmpty) return <String>[];
        // Try JSON decode if it looks like a JSON array
        if (s.startsWith('[') && s.endsWith(']')) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is List) {
              return decoded.map((e) => e?.toString() ?? '').toList();
            }
          } catch (_) {
            // fall through to comma-split
          }
        }
        // Fallback: comma-separated values
        return s
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Conoll_Class(
      id: parseInt(json['id']),
      period: parseInt(json['period']),
      students: parseStudents(json['students']),
      // DB column is 'subject'
      subjectId: parseInt(json['subject'] ?? json['subjectId']),
      room: parseInt(json['room']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'students': students,
      'subject': subjectId,
      'room': room,
    };
  }
}
