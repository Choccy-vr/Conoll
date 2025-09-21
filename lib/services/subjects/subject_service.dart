import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/users/User.dart';

import '/services/supabase/DB/supabase_db.dart';
import 'Conoll_Subject.dart';

class SubjectService {
  static Future<List<Conoll_Subject>> getSubjectsInAGrade(int grade) async {
    try {
      final response = await SupabaseDB.GetMultipleRowData(
        table: 'subjects',
        column: 'grade',
        columnValue: [grade],
      );

      return (response as List)
          .map((json) => Conoll_Subject.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting subjects in grade $grade: $e');
    }
  }

  static Future<Conoll_Subject?> getSubjectById(int id) async {
    try {
      final response = await SupabaseDB.GetRowData(
        table: 'subjects',
        rowID: id,
      );
      return Conoll_Subject.fromJson(response);
    } catch (e) {
      throw Exception('Error getting subject by ID $id: $e');
    }
  }

  static Future<Conoll_Subject> createSubject({
    required String name,
    required String teacher,
    required int grade,
  }) async {
    try {
      final room = await RoomService.createRoom(
        name: name,
        members: [UserService.currentUser?.id ?? ''],
        type: RoomType.subject,
      );
      final response = await SupabaseDB.InsertAndReturnData(
        table: 'subjects',
        data: {
          'name': name,
          'teacher': teacher,
          'grade': grade,
          'room': room.id,
        },
      );
      return Conoll_Subject.fromJson(response.first);
    } catch (e) {
      throw Exception('Error creating subject: $e');
    }
  }

  static Future<Conoll_Subject> joinSubject({required int subjectId}) async {
    try {
      final subject = await getSubjectById(subjectId);
      if (subject == null) {
        throw Exception('Subject with id $subjectId not found');
      }
      await SupabaseDB.CallDBFunction(
        functionName: 'add-user-subject',
        parameters: {
          'user_id': UserService.currentUser?.id ?? '',
          'subject': subjectId,
        },
      );
      await RoomService.addUserToRoom(
        roomId: subject.room.toString(),
        userId: UserService.currentUser?.id ?? '',
      );
      final response = await SupabaseDB.GetRowData(
        table: 'subjects',
        rowID: subjectId,
      );
      return Conoll_Subject.fromJson(response);
    } catch (e) {
      throw Exception('Error joining subject: $e');
    }
  }
}
