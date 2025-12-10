import 'package:client/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/notification_model.dart';
import '../../../../../data/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _notificationService.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _tabController.index == 0
        ? _notificationService.notifications
        : _notificationService.notifications.where((n) => !n.isRead).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    child: Icon(Icons.arrow_back, color: Colors.white),
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white, size: 24),
                    color: Color(0xff2B2D33),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    itemBuilder: (context) => [
                      if (_notificationService.unreadCount > 0)
                        PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(
                                Icons.done_all,
                                color: Colors.white70,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Mark all read',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'clear_read',
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear_all,
                              color: Colors.white70,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Clear read',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Clear all',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'mark_all_read') {
                        _notificationService.markAllAsRead();
                      } else if (value == 'clear_read') {
                        _notificationService.clearRead();
                      } else if (value == 'clear_all') {
                        _showClearAllDialog();
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),

              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xff2B2D33),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Color(0xff44474E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: (_) => setState(() {}),
                  tabs: [
                    Tab(
                      text:
                          'All (${_notificationService.notifications.length})',
                    ),
                    Tab(text: 'Unread (${_notificationService.unreadCount})'),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _NotificationCard(
                            notification: notifications[index],
                            onTap: () =>
                                _handleNotificationTap(notifications[index]),
                            onDelete: () => _notificationService
                                .deleteNotification(notifications[index].id),
                          );
                        },
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
          Icon(Icons.notifications_none, size: 80, color: Colors.white30),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    _notificationService.markAsRead(notification.id);

    if (notification.actionData != null) {
      print('Action data: ${notification.actionData}');
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff2B2D33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all notifications?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              _notificationService.clearAll();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(notification.timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead ? Color(0xff2B2D33) : Color(0xff44474E),
            borderRadius: BorderRadius.circular(8),
            border: notification.isRead
                ? null
                : Border.all(
                    color: AppColors.warning.withOpacity(0.4),
                    width: 1.2,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xff222222),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(color: Color(0xff9E9FA4), fontSize: 11),
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

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    required this.count,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            right: 4,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(count > 9 ? 4 : 5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              constraints: BoxConstraints(
                minWidth: count > 9 ? 20 : 18,
                minHeight: count > 9 ? 20 : 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: count > 9 ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
