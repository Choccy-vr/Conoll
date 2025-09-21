import 'package:flutter/material.dart';
import 'package:conoll/services/users/Conoll_User.dart';
import 'package:conoll/services/users/User.dart';
import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/chat/room/Room.dart';

class CreateChatDialog extends StatefulWidget {
  const CreateChatDialog({super.key});

  @override
  State<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<CreateChatDialog>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Conoll_User> _selectedMembers = [];
  List<Conoll_User> _searchResults = [];
  bool _isSearching = false;
  bool _isCreating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Add the current user to the selected members list by default
    if (UserService.currentUser != null) {
      _selectedMembers.add(UserService.currentUser!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await UserService.searchUsers(query);
      // Filter out users who are already selected
      final currentMemberIds = _selectedMembers.map((m) => m.id).toSet();
      setState(() {
        _searchResults = results
            .where((user) => !currentMemberIds.contains(user.id))
            .toList();
      });
    } catch (e) {
      _showSnackBar('Error searching users: $e', isError: true);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addMember(Conoll_User user) {
    setState(() {
      _selectedMembers.add(user);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(Conoll_User user) {
    // Prevent removing the current user
    if (user.id == UserService.currentUser?.id) return;
    setState(() {
      _selectedMembers.removeWhere((member) => member.id == user.id);
    });
  }

  Future<void> _createChat() async {
    if (_selectedMembers.length < 2) {
      _showSnackBar(
        'You must select at least one other member.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final memberIds = _selectedMembers.map((m) => m.id).toList();
      final roomType = memberIds.length > 2 ? RoomType.group : RoomType.direct;

      String roomName = _nameController.text.trim();
      if (roomName.isEmpty) {
        if (roomType == RoomType.direct) {
          // Auto-generate name for direct chats
          final otherUser = _selectedMembers.firstWhere(
            (u) => u.id != UserService.currentUser?.id,
          );
          roomName = otherUser.name;
        } else {
          _showSnackBar(
            'Please enter a name for this group chat.',
            isError: true,
          );
          setState(() => _isCreating = false);
          return;
        }
      }

      await RoomService.createRoom(
        name: roomName,
        members: memberIds,
        type: roomType,
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showSnackBar('Failed to create chat: $e', isError: true);
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: size.width > 500 ? 500 : size.width - 40,
          height: size.height * 0.8,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Chat',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Start a conversation with your contacts',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chat Name Field
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Chat name (optional for direct messages)',
                          hintText: 'Enter a name for this chat',
                          prefixIcon: const Icon(Icons.edit),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Members Section
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Members (${_selectedMembers.length})',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Selected Members Chips
                      if (_selectedMembers.isNotEmpty)
                        Container(
                          height: 70,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _selectedMembers.map((user) {
                                final isCurrentUser =
                                    user.id == UserService.currentUser?.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: colorScheme.primary,
                                      child: Text(
                                        user.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    label: Text(
                                      isCurrentUser ? 'You' : user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    deleteIcon: isCurrentUser
                                        ? null
                                        : const Icon(Icons.close, size: 18),
                                    onDeleted: isCurrentUser
                                        ? null
                                        : () => _removeMember(user),
                                    backgroundColor: colorScheme
                                        .primaryContainer
                                        .withOpacity(0.5),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Search Field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users',
                          hintText: 'Search by name or @handle',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        onChanged: _searchUsers,
                      ),
                      const SizedBox(height: 12),

                      // Search Results
                      Expanded(
                        child: _searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchController.text.isEmpty
                                          ? Icons.person_search
                                          : Icons.search_off,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'Start typing to search for users'
                                          : 'No users found',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        child: Text(
                                          user.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text('@${user.handle}'),
                                      trailing: Icon(
                                        Icons.add,
                                        color: colorScheme.primary,
                                      ),
                                      onTap: () => _addMember(user),
                                      shape: index == _searchResults.length - 1
                                          ? const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(12),
                                                bottomRight: Radius.circular(
                                                  12,
                                                ),
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with Create Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreating
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createChat,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: _isCreating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Creating...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble,
                                    size: 20,
                                    color: colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Create Chat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
