import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/classes/Conoll_Class.dart';
import 'package:conoll/services/classes/class_service.dart';
import 'package:conoll/services/subjects/Conoll_Subject.dart';
import 'package:conoll/services/subjects/subject_service.dart';

import '/services/supabase/DB/supabase_db.dart';
import 'Conoll_User.dart';

class UserService {
  static Conoll_User? currentUser;

  static Future<Conoll_User?> getUserById(String id) async {
    try {
      final response = await SupabaseDB.GetRowData(table: 'users', rowID: id);
      return Conoll_User.fromJson(response);
    } catch (e) {
      // User not found or other database error
      print('Error getting user by ID $id: $e');
      return null;
    }
  }

  static Future<Conoll_User?> getUserByHandle(String handle) async {
    try {
      final response = await SupabaseDB.GetRowData(
        table: 'users',
        rowID: handle,
      );
      return Conoll_User.fromJson(response);
    } catch (e) {
      // User not found or other database error
      print('Error getting user by handle $handle: $e');
      return null;
    }
  }

  static Future<List<Conoll_User>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      if (query.startsWith('@')) {
        // Search by handle
        final handle = query.substring(1);
        final response = await SupabaseDB.supabase
            .from('users')
            .select()
            .ilike('handle', '%$handle%')
            .limit(10);
        return (response as List)
            .map((json) => Conoll_User.fromJson(json))
            .toList();
      } else {
        // Search by name or username
        final response = await SupabaseDB.supabase
            .from('users')
            .select()
            .or('name.ilike.%$query%,username.ilike.%$query%')
            .limit(10);
        return (response as List)
            .map((json) => Conoll_User.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  static Future<void> setCurrentUser(String id) async {
    final user = await getUserById(id);
    if (user == null) {
      throw Exception(
        'User initialization failed: Could not retrieve user after creation',
      );
    }

    currentUser = user;
  }

  static Future<void> updateUser() async {
    SupabaseDB.UpsertData(table: 'users', data: currentUser?.toJson());
  }

  static Future<void> updateCurrentUser() async {
    currentUser = await getUserById(currentUser?.id ?? '');
  }

  static Future<void> initializeUser({
    required String id,
    required String name,
    required String username,
    required int grade,
    required List<Conoll_Class> classes,
  }) async {
    // Store class IDs as strings for DB compatibility
    final classIds = classes.map((c) => c.id.toString()).toList();
    final handle = username.toLowerCase().replaceAll(' ', '-');
    List<Conoll_Subject> userSubjects = [];
    final response = await SupabaseDB.InsertAndReturnData(
      table: 'users',
      data: {
        'id': id,
        'name': name,
        'username': username,
        'grade': grade,
        'classes': classIds,
        'handle': handle,
      },
    );

    // Add user to grade room (9->69, 10->70, 11->71, 12->72)
    int? gradeRoomId;
    switch (grade) {
      case 9:
        gradeRoomId = 69;
        break;
      case 10:
        gradeRoomId = 70;
        break;
      case 11:
        gradeRoomId = 71;
        break;
      case 12:
        gradeRoomId = 72;
        break;
    }

    if (gradeRoomId != null) {
      RoomService.addUserToRoom(roomId: gradeRoomId.toString(), userId: id);
    }

    // Add user to all classes
    for (final classObj in classes) {
      ClassService.joinClass(classId: classObj.id);
      userSubjects.add(
        await SubjectService.getSubjectById(classObj.subjectId)
            as Conoll_Subject,
      );
    }

    for (final subject in userSubjects) {
      SubjectService.joinSubject(subjectId: int.parse(subject.id));
    }

    // Give the database a moment to process the insert
    await Future.delayed(Duration(milliseconds: 100));
    final userId = Conoll_User.fromJson(response[0]).id;

    final user = await getUserById(userId);

    if (user == null) {
      throw Exception(
        'User initialization failed: Could not retrieve user after creation',
      );
    }

    currentUser = user;
  }
}
