import 'package:flutter/material.dart';
import 'package:conoll/services/chat/room/Room.dart';
import 'package:conoll/services/chat/room/room_service.dart';
import 'package:conoll/services/users/User.dart';
import 'package:conoll/widgets/dialogs/create_chat_dialog.dart';
import 'package:conoll/services/navigation/navigation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Room> _allRooms = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserRooms();
  }

  Future<void> _loadUserRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (UserService.currentUser?.id != null) {
        final rooms = await RoomService.getRoomsForUser(
          UserService.currentUser!.id,
        );
        setState(() {
          _allRooms = rooms;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load rooms: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomNavigation(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        'Conoll',
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUserRooms,
          tooltip: 'Refresh rooms',
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profile'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) {
            _handleMenuSelection(value.toString());
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildClassesTab(context);
      case 1:
        return _buildSubjectsTab(context);
      case 2:
        return _buildGradeAndSchoolTab(context);
      case 3:
        return _buildDirectAndGroupsTab(context);
      default:
        return _buildClassesTab(context);
    }
  }

  Widget _buildClassesTab(BuildContext context) {
    return Column(
      children: [
        _buildTabHeader(context, 'Classes'),
        Expanded(child: _buildRoomsList(context, [RoomType.classRoom])),
      ],
    );
  }

  Widget _buildSubjectsTab(BuildContext context) {
    return Column(
      children: [
        _buildTabHeader(context, 'Subjects'),
        Expanded(child: _buildRoomsList(context, [RoomType.subject])),
      ],
    );
  }

  Widget _buildGradeAndSchoolTab(BuildContext context) {
    return Column(
      children: [
        _buildTabHeader(context, 'Grade & School'),
        Expanded(child: _buildRoomsList(context, [RoomType.grade])),
      ],
    );
  }

  Widget _buildDirectAndGroupsTab(BuildContext context) {
    return Column(
      children: [
        _buildTabHeader(context, 'Messages & Groups'),
        Expanded(
          child: _buildRoomsList(context, [RoomType.direct, RoomType.group]),
        ),
      ],
    );
  }

  Widget _buildTabHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (_selectedIndex ==
              3) // Only show create button on Messages & Groups tab
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreateChatDialog(),
                ).then((created) {
                  if (created == true) {
                    _loadUserRooms();
                  }
                });
              },
              icon: const Icon(Icons.add),
              tooltip: 'Create new chat',
            ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, List<RoomType> roomTypes) {
    final rooms = _allRooms
        .where((room) => roomTypes.contains(room.room_type))
        .toList();

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No rooms yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (roomTypes.contains(RoomType.group) ||
                roomTypes.contains(RoomType.direct))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreateChatDialog(),
                    ).then((created) {
                      if (created == true) {
                        _loadUserRooms();
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Chat'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserRooms,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomTile(context, room, _getRoomColor(room.room_type));
        },
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, Room room, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(_getRoomIcon(room.room_type), color: color, size: 20),
        ),
        title: Text(
          room.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${room.members.length} members',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => _openRoom(context, room),
      ),
    );
  }

  IconData _getRoomIcon(RoomType roomType) {
    switch (roomType) {
      case RoomType.classRoom:
        return Icons.class_;
      case RoomType.subject:
        return Icons.subject;
      case RoomType.grade:
        return Icons.school;
      case RoomType.group:
        return Icons.group;
      case RoomType.direct:
        return Icons.person;
    }
  }

  Color _getRoomColor(RoomType roomType) {
    switch (roomType) {
      case RoomType.classRoom:
        return Colors.blue;
      case RoomType.subject:
        return Colors.green;
      case RoomType.grade:
        return Colors.orange;
      case RoomType.group:
        return Colors.purple;
      case RoomType.direct:
        return Colors.teal;
    }
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.class_outlined),
          selectedIcon: Icon(Icons.class_),
          label: 'Classes',
        ),
        NavigationDestination(
          icon: Icon(Icons.subject_outlined),
          selectedIcon: Icon(Icons.subject),
          label: 'Subjects',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Grade & School',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(Icons.chat),
          label: 'Messages',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreateChatDialog(),
        ).then((created) {
          if (created == true) {
            _loadUserRooms();
          }
        });
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      child: const Icon(Icons.add_comment),
      tooltip: 'Create new chat',
    );
  }

  void _openRoom(BuildContext context, Room room) {
    NavigationService.openChat(context: context, room: room);
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        // TODO: Navigate to profile page
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile coming soon')));
        break;
      case 'logout':
        // TODO: Implement logout
        UserService.currentUser = null;
        Navigator.pushReplacementNamed(context, '/login');
        break;
    }
  }
}
