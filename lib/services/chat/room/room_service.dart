import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/supabase/DB/supabase_db.dart';

class RoomService {
  static Future<List<Room>> getRoomsForUser(String userId) async {
    try {
      final response = await SupabaseDB.supabase
          .from('rooms')
          .select()
          .contains('members', [userId]);

      return (response as List).map((json) => Room.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error getting rooms for user $userId: $e');
    }
  }

  static Future<Room?> getRoomById(String roomId) async {
    try {
      final response = await SupabaseDB.GetRowData(
        table: 'rooms',
        rowID: roomId,
      );
      return Room.fromJson(response);
    } catch (e) {
      throw Exception('Error getting room by ID $roomId: $e');
    }
  }

  static Future<Room> createRoom({
    required String name,
    required List<String> members,
    required RoomType type,
  }) async {
    try {
      final response = await SupabaseDB.InsertAndReturnData(
        table: 'rooms',
        data: {'name': name, 'members': members, 'room_type': type.name},
      );
      return Room.fromJson(response.first);
    } catch (e) {
      throw Exception('Error creating room: $e');
    }
  }

  static Future<void> addUserToRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      await SupabaseDB.CallDBFunction(
        functionName: 'add_member_to_room',
        parameters: {'room': roomId, 'user_id': userId},
      );
    } catch (e) {
      throw Exception('Error adding user to room: $e');
    }
  }
}
