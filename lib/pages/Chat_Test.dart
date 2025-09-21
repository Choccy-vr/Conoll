import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:conoll/services/chat/message/Message.dart';
import 'package:conoll/services/chat/message/message_service.dart';
import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/users/User.dart';

class ChatTestPage extends StatefulWidget {
  const ChatTestPage({super.key});

  @override
  State<ChatTestPage> createState() => _ChatTestPageState();
}

class _ChatTestPageState extends State<ChatTestPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  List<Room> _userRooms = [];
  Room? _currentRoom;
  String? _currentUserId;
  bool _isListening = false;
  RoomType _selectedRoomType = RoomType.direct;

  @override
  void initState() {
    super.initState();
    _initializeTest();
    _setupMessageStream();
  }

  void _initializeTest() {
    _currentUserId = UserService.currentUser?.id;
    if (_currentUserId != null) {
      _loadUserRooms();
    }
  }

  void _setupMessageStream() {
    MessageService.currentMessageStream.stream.listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) {
          _showSnackBar('Stream error: $error', isError: true);
        }
      },
    );
  }

  Future<void> _loadUserRooms() async {
    try {
      if (_currentUserId != null) {
        final rooms = await RoomService.getRoomsForUser(_currentUserId!);
        setState(() {
          _userRooms = rooms;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load rooms: $e', isError: true);
    }
  }

  void _joinRoom(Room room) {
    if (_currentRoom?.id == room.id) return;

    setState(() {
      _currentRoom = room;
      _isListening = true;
      _messages = []; // Clear previous messages
    });

    // Fetch initial messages and then listen for new ones
    _loadInitialMessages(room.id);
    MessageService.listen(room.id);
    _showSnackBar('Joined room: ${room.name}');
  }

  void _joinRoomById() {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) return;

    final tempRoom = Room(
      id: roomId,
      name: 'Test Room ($roomId)',
      createdAt: DateTime.now(),
      room_type: RoomType.direct,
      members: [],
    );

    setState(() {
      _currentRoom = tempRoom;
      _isListening = true;
      _messages = []; // Clear previous messages
    });

    // Fetch initial messages and then listen for new ones
    _loadInitialMessages(roomId);
    MessageService.listen(roomId);
    _showSnackBar('Joined room: $roomId');
    _roomIdController.clear();
  }

  Future<void> _loadInitialMessages(String roomId) async {
    try {
      final messages = await MessageService.getMessagesForRoom(roomId);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar('Failed to load initial messages: $e', isError: true);
    }
  }

  void _leaveRoom() {
    MessageService.dispose();
    setState(() {
      _currentRoom = null;
      _messages = [];
      _isListening = false;
    });
    _showSnackBar('Left room');
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentRoom == null) return;

    try {
      await MessageService.sendMessage(content, _currentRoom!.id);
      _messageController.clear();
    } catch (e) {
      _showSnackBar('Failed to send message: $e', isError: true);
    }
  }

  Future<void> _createTestRoom() async {
    final name = _roomNameController.text.trim();
    if (name.isEmpty || _currentUserId == null) {
      _showSnackBar('Room name cannot be empty.', isError: true);
      return;
    }

    final membersString = _membersController.text.trim();
    final memberIds = membersString.isNotEmpty
        ? membersString.split(',').map((e) => e.trim()).toList()
        : <String>[];

    // Automatically add the current user
    if (!memberIds.contains(_currentUserId!)) {
      memberIds.add(_currentUserId!);
    }

    try {
      final room = await RoomService.createRoom(
        name: name,
        members: memberIds,
        type: _selectedRoomType,
      );

      setState(() {
        _userRooms.add(room);
      });

      _roomNameController.clear();
      _membersController.clear();
      _showSnackBar('Created room: ${room.name}');
    } catch (e) {
      _showSnackBar('Failed to create room: $e', isError: true);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final localTimestamp = timestamp.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );

    if (messageDate == today) {
      return DateFormat.jm().format(localTimestamp); // e.g., 5:08 PM
    } else {
      return DateFormat.MMMd().format(localTimestamp); // e.g., Sep 20
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  void dispose() {
    MessageService.dispose();
    _messageController.dispose();
    _roomNameController.dispose();
    _roomIdController.dispose();
    _membersController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Test Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            onPressed: _isListening ? _leaveRoom : null,
            tooltip: _isListening ? 'Leave Room' : 'Not Listening',
          ),
        ],
      ),
      body: Column(
        children: [
          // User & Room Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ID: ${_currentUserId ?? "Not logged in"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Room: ${_currentRoom?.name ?? "None"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_currentRoom != null)
                  Text(
                    'Room ID: ${_currentRoom!.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Room Management Section
          ExpansionTile(
            title: const Text('Room Management'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a New Room',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Create Room
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        labelText: 'New Room Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoomType>(
                      value: _selectedRoomType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        border: OutlineInputBorder(),
                      ),
                      items: RoomType.values.map((RoomType type) {
                        return DropdownMenuItem<RoomType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (RoomType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRoomType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _membersController,
                      decoration: const InputDecoration(
                        labelText: 'Other Member IDs (comma-separated)',
                        hintText: 'e.g., user-id-1,user-id-2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createTestRoom,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Create Room'),
                      ),
                    ),
                    const Divider(height: 32),

                    // Join by ID
                    const Text(
                      'Join or List Rooms',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _roomIdController,
                            decoration: const InputDecoration(
                              labelText: 'Join Room by ID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _joinRoomById,
                          child: const Text('Join'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User Rooms List
                    if (_userRooms.isNotEmpty) ...[
                      const Text(
                        'Your Rooms:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          itemCount: _userRooms.length,
                          itemBuilder: (context, index) {
                            final room = _userRooms[index];
                            final isActive = _currentRoom?.id == room.id;
                            return Card(
                              color: isActive ? Colors.blue[100] : null,
                              child: ListTile(
                                title: Text(room.name),
                                subtitle: Text('ID: ${room.id}'),
                                trailing: Icon(
                                  isActive
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isActive ? Colors.blue : null,
                                ),
                                onTap: () => _joinRoom(room),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _currentRoom == null
                  ? const Center(
                      child: Text(
                        'Select or join a room to start chatting',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMyMessage = message.senderId == _currentUserId;

                        return Align(
                          alignment: isMyMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isMyMessage
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMyMessage)
                                  Text(
                                    'User: ${message.senderId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Text(
                                  message.content,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(message.timestamp),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Message Input
          if (_currentRoom != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
