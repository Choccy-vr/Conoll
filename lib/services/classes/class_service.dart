import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/subjects/subject_service.dart';
import 'package:conoll/services/users/User.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/services/supabase/DB/supabase_db.dart';
import 'Conoll_Class.dart';

class ClassService {
  static Future<List<Conoll_Class>> getClassesForSubject(int subjectId) async {
    try {
      final response = await SupabaseDB.GetMultipleRowData(
        table: 'classes',
        column: 'subject',
        columnValue: [subjectId],
      );

      return (response as List)
          .map((json) => Conoll_Class.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting classes for subject $subjectId: $e');
      return [];
    }
  }

  static Future<Conoll_Class?> getClassById(int classId) async {
    try {
      final response = await SupabaseDB.GetRowData(
        table: 'classes',
        rowID: classId,
      );
      return Conoll_Class.fromJson(response);
    } catch (e) {
      print('Error getting class by ID $classId: $e');
      return null;
    }
  }

  static Future<Conoll_Class> CreateClass({
    required int period,
    required int subjectId,
  }) async {
    try {
      final subject = await SubjectService.getSubjectById(subjectId);
      if (subject == null) {
        throw Exception('Subject with id $subjectId not found');
      }
      final room = await RoomService.createRoom(
        name: '${subject.name} - Period $period',
        members: [UserService.currentUser?.id ?? ''],
        type: RoomType.classRoom,
      );
      final response = await SupabaseDB.InsertAndReturnData(
        table: 'classes',
        data: {'period': period, 'subject': subjectId, 'room': room.id},
      );
      return Conoll_Class.fromJson(response.first);
    } catch (e) {
      throw Exception('Error creating class: $e');
    }
  }

  static Future<Conoll_Class> joinClass({required int classId}) async {
    try {
      final classObj = await getClassById(classId);
      if (classObj == null) {
        throw Exception('Class with id $classId not found');
      }
      await SupabaseDB.CallDBFunction(
        functionName: 'add-user-class',
        parameters: {
          'user_id': UserService.currentUser?.id ?? '',
          'class': classId,
        },
      );
      await RoomService.addUserToRoom(
        roomId: classObj.room.toString(),
        userId: UserService.currentUser?.id ?? '',
      );
      final response = await SupabaseDB.GetRowData(
        table: 'classes',
        rowID: classId,
      );
      return Conoll_Class.fromJson(response);
    } catch (e) {
      throw Exception('Error joining class: $e');
    }
  }
}
