import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:conoll/services/chat/message/Message.dart';
import 'package:conoll/services/chat/message/message_service.dart';
import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/users/User.dart';

class ChatPage extends StatefulWidget {
  final Room room;

  const ChatPage({super.key, required this.room});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  String? _currentUserId;
  bool _isLoading = true;
  Map<String, String> _userNames = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    _currentUserId = UserService.currentUser?.id;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Set up real-time message stream first
      _setupMessageStream();

      // Start listening to the room for real-time updates
      MessageService.listen(widget.room.id);

      // Load initial messages
      await _loadInitialMessages();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Failed to initialize chat: $e', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupMessageStream() {
    // Listen to the message stream and update UI
    MessageService.currentMessageStream.stream.listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          // Small delay to ensure UI is updated before scrolling
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _showSnackBar('Stream error: $error', isError: true);
        }
      },
    );
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await MessageService.getMessagesForRoom(widget.room.id);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar('Failed to load messages: $e', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear the input immediately for better UX
    _messageController.clear();

    try {
      await MessageService.sendMessage(content, widget.room.id);
      // The real-time stream should automatically update the UI
      // but we'll scroll to bottom to ensure the new message is visible
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToBottom();
      });
    } catch (e) {
      _showSnackBar('Failed to send message: $e', isError: true);
      // Restore the message text if sending failed
      _messageController.text = content;
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

  Future<String> _getUserName(String userId) async {
    // Return cached name if available
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }

    // If it's the current user, return "You"
    if (userId == _currentUserId) {
      _userNames[userId] = 'You';
      return 'You';
    }

    try {
      final user = await UserService.getUserById(userId);
      final name = user?.name ?? 'Unknown User';
      _userNames[userId] = name;
      return name;
    } catch (e) {
      _userNames[userId] = 'Unknown User';
      return 'Unknown User';
    }
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

  Widget _buildMessageBubble(Message message) {
    final isMyMessage = message.senderId == _currentUserId;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _getUserName(message.senderId),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Loading...';

        return Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMyMessage ? 60 : 16,
            right: isMyMessage ? 16 : 60,
          ),
          child: Column(
            crossAxisAlignment: isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Show sender name for other people's messages
              if (!isMyMessage)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    userName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMyMessage ? 20 : 4),
                    topRight: Radius.circular(isMyMessage ? 4 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isMyMessage
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isMyMessage
                                    ? colorScheme.onPrimary.withOpacity(0.8)
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                        if (isMyMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done,
                            size: 14,
                            color: colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    MessageService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                widget.room.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.room.members.length} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  // TODO: Show room info
                  _showSnackBar('Room info coming soon');
                  break;
                case 'members':
                  // TODO: Show members list
                  _showSnackBar('Members list coming soon');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Room Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.people_outline),
                    SizedBox(width: 8),
                    Text('Members'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_messages.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        Icons.send_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
