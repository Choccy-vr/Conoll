import 'dart:async';
import 'package:conoll/services/chat/message/Message.dart';
import 'package:conoll/services/supabase/DB/supabase_db.dart';
import 'package:conoll/services/users/User.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  static var currentMessageStream = StreamController<List<Message>>.broadcast();

  static StreamSubscription<List<Map<String, dynamic>>>? _channel;

  static void listen(String roomId) {
    // Cancel any existing subscription to avoid duplicates
    _channel?.cancel();

    // Re-initialize the stream controller for the new room if needed
    if (currentMessageStream.isClosed) {
      currentMessageStream = StreamController<List<Message>>.broadcast();
    }

    print('Starting to listen to room: $roomId'); // Debug log

    _channel = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room', roomId) // Corrected column name
        .order('created_at', ascending: true)
        .listen(
          (data) {
            print('Received ${data.length} messages from stream'); // Debug log
            final messages = data
                .map((item) => Message.fromJson(item))
                .toList();
            currentMessageStream.add(messages);
          },
          onError: (error) {
            print('Error listening to messages: $error');
            currentMessageStream.addError(error);
          },
        );
  }

  static void dispose() {
    if (_channel != null) {
      _channel?.cancel();
      _channel = null;
    }
    if (!currentMessageStream.isClosed) {
      currentMessageStream.close();
    }
  }

  static Future<Message> sendMessage(String message, String roomId) async {
    try {
      print('Sending message to room $roomId: $message'); // Debug log
      final response = await SupabaseDB.InsertAndReturnData(
        table: 'messages',
        data: {
          'content': message,
          'room': roomId,
          'user': UserService.currentUser?.id,
        },
      );
      print('Message sent successfully'); // Debug log
      return Message.fromJson(response.first);
    } catch (e) {
      print('Error sending message: $e'); // Debug log
      throw Exception('Error sending message: $e');
    }
  }

  static Future<List<Message>> getMessagesForRoom(String roomId) async {
    try {
      final response = await SupabaseDB.supabase
          .from('messages')
          .select()
          .eq('room', roomId) // Corrected column name from 'room_id' to 'room'
          .order('created_at', ascending: true);

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error getting messages for room $roomId: $e');
    }
  }
}
