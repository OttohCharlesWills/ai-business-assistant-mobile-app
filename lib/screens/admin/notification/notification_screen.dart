import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/app_loader.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {

  static const bgColor    = Color(0xFF0C1F3F);
  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  late TabController _tabController;

  bool loading = false;
  List unread = [];
  List read   = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    setState(() => loading = true);

    final data = await NotificationService.getNotifications(refresh: refresh);

    if (data != null) {
      setState(() {
        unread      = data['unread'] ?? [];
        read        = data['read'] ?? [];
        unreadCount = data['unread_count'] ?? 0;
      });
    }

    setState(() => loading = false);
  }

  Future<void> markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    fetchNotifications(refresh: true);
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    fetchNotifications(refresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All marked as read"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> deleteNotification(String id) async {
    await NotificationService.deleteNotification(id);
    fetchNotifications(refresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification deleted"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                "Clear All",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "This will permanently delete all notifications.",
                textAlign: TextAlign.center,
                style: TextStyle(color: softBlue, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentBlue.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel",
                          style: TextStyle(color: softBlue)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Clear All",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await NotificationService.deleteAll();
      fetchNotifications(refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All notifications cleared"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Extract readable message from notification data
  String _getMessage(Map n) {
    final data = n['data'];
    if (data is Map) {
      return data['message']?.toString() ??
          data['body']?.toString() ??
          "New notification";
    }
    return "New notification";
  }

  String _getTitle(Map n) {
    final data = n['data'];
    if (data is Map) {
      return data['type']?.toString().replaceAll('_', ' ').toUpperCase() ??
          "Notification";
    }
    return "Notification";
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!loading && (unread.isNotEmpty || read.isNotEmpty))
            PopupMenuButton(
              color: cardColor,
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text("Mark all as read",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 10),
                      Text("Clear all",
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 1) markAllAsRead();
                if (value == 2) deleteAll();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => fetchNotifications(refresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentBlue,
          labelColor: Colors.white,
          unselectedLabelColor: softBlue,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: "Unread${unreadCount > 0 ? ' ($unreadCount)' : ''}"),
            Tab(text: "Read (${read.length})"),
          ],
        ),
      ),

      body: loading
          ? const FullScreenLoader(message: "Loading notifications...")
          : TabBarView(
              controller: _tabController,
              children: [
                // UNREAD TAB
                _buildList(
                  notifications: unread,
                  isUnread: true,
                  emptyMessage: "No unread notifications",
                  emptyIcon: Icons.notifications_none_rounded,
                ),

                // READ TAB
                _buildList(
                  notifications: read,
                  isUnread: false,
                  emptyMessage: "No read notifications",
                  emptyIcon: Icons.done_all_rounded,
                ),
              ],
            ),
    );
  }

  Widget _buildList({
    required List notifications,
    required bool isUnread,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 40, color: softBlue),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchNotifications(refresh: true),
      color: accentBlue,
      backgroundColor: cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index] as Map;
          final id = n['id']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? accentBlue.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),

              // Dot indicator for unread
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnread
                      ? accentBlue.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_rounded,
                  color: isUnread ? accentBlue : softBlue,
                  size: 22,
                ),
              ),

              title: Text(
                _getTitle(n),
                style: TextStyle(
                  color: isUnread ? Colors.white : softBlue,
                  fontWeight:
                      isUnread ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _getMessage(n),
                    style: TextStyle(
                      color: isUnread ? softBlue : softBlue.withOpacity(0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(n['created_at']?.toString()),
                    style: TextStyle(
                      color: softBlue.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              trailing: PopupMenuButton(
                color: bgColor,
                icon: const Icon(Icons.more_vert_rounded,
                    color: softBlue, size: 18),
                itemBuilder: (_) => [
                  if (isUnread)
                    const PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.done_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text("Mark as read",
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Text("Delete",
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 1) markAsRead(id);
                  if (value == 2) deleteNotification(id);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}