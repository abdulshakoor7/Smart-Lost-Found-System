import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';
import 'chat_screen.dart';
import '../core/utils/time_manager.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final Color blue = const Color(0xFF0F172A);
  final Color bluegray = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    // Real-time polling: Refresh the updates list every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadAlerts();
    });
  }

  Future<void> _loadAlerts() async {
    final data = await ApiService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
            "Notifications",
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold
            )
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _vibrantBlue),
            onPressed: _loadAlerts,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _vibrantBlue))
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadAlerts,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(_notifications[index]);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> alert) {
    bool isRead = alert['is_read'] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Detect notification type and target ID
    String type = alert['notification_type'] ?? 'MATCH';
    var rawTargetId = alert['target_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Theme.of(context).cardColor : _vibrantBlue.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // 1. Mark as read for professional sync
            if (alert['id'] != null) {
              await ApiService.markNotificationRead(alert['id']);
            }

            // 2. Extract the Target ID (The ID of the matched item)
            final int? targetId = alert['target_id'];
            final String type = alert['notification_type'] ?? 'MATCH';

            if (targetId != null && targetId != 0) {
              if (type == 'CHAT') {
                // Logic for Chat deep-link
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: "room_$targetId",
                      title: "Chat Support",
                      receiverEmail: alert['sender_email'] ?? "",
                    )
                ));
              } else {
                // ✅ THE GENIUS FIX: Navigate to ItemDetail with JUST the ID
                // Our new ItemDetailScreen logic will see this ID and fetch the full data!
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(
                    itemData: {
                      'id': targetId,
                      'title': 'Loading match...', // Placeholder until fetch completes
                    },
                  ),
                ));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error: Item ID missing in notification.")),
              );
            }
          },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _vibrantBlue.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    type == 'CHAT'
                        ? Icons.chat_bubble_outline
                        : (type == 'MATCH' ? Icons.auto_awesome : Icons.notifications_active_outlined),
                    color: _vibrantBlue,
                    size: 24
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          alert['title'] ?? "New Alert",
                          style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: _vibrantBlue, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert['message'] ?? "",
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontSize: 13,
                          height: 1.4
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      TimeManager.formatTimestamp(alert['created_at'] ?? ""),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withValues(alpha:0.2)),
          const SizedBox(height: 16),
          const Text("No new notifications", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}