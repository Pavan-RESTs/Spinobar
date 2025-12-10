

// ==================== NOTIFICATION PAGE ====================
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

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  NotificationType? _filterType;

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
    final notifications = _filterType == null
        ? (_tabController.index == 0
        ? _notificationService.notifications
        : _notificationService.unreadNotifications)
        : _notificationService.getNotificationsByType(_filterType!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Custom App Bar
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
                              Icon(Icons.done_all, color: Colors.white70, size: 20),
                              SizedBox(width: 10),
                              Text('Mark all read', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'clear_read',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, color: Colors.white70, size: 20),
                            SizedBox(width: 10),
                            Text('Clear read', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text('Clear all', style: TextStyle(color: Colors.red)),
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

              // Tab Bar
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
                  onTap: (_) => setState(() => _filterType = null),
                  tabs: [
                    Tab(text: 'All (${_notificationService.notifications.length})'),
                    Tab(text: 'Unread (${_notificationService.unreadCount})'),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Filter Chips
              _buildFilterChips(),
              SizedBox(height: 16),

              // Notifications List
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _NotificationCard(
                      notification: notifications[index],
                      onTap: () => _handleNotificationTap(notifications[index]),
                      onDelete: () => _notificationService.deleteNotification(
                        notifications[index].id,
                      ),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Alert',
            color: Colors.red,
            isSelected: _filterType == NotificationType.alert,
            onTap: () => setState(() => _filterType = NotificationType.alert),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Warning',
            color: AppColors.warning,
            isSelected: _filterType == NotificationType.warning,
            onTap: () => setState(() => _filterType = NotificationType.warning),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Info',
            color: Colors.blueAccent,
            isSelected: _filterType == NotificationType.info,
            onTap: () => setState(() => _filterType = NotificationType.info),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: 'Success',
            color: AppColors.success,
            isSelected: _filterType == NotificationType.success,
            onTap: () => setState(() => _filterType = NotificationType.success),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.white30,
          ),
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
            style: TextStyle(
              color: Colors.white30,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    _notificationService.markAsRead(notification.id);
    // Handle notification action here based on actionData
    if (notification.actionData != null) {
      // Navigate or perform action
      print('Action data: ${notification.actionData}');
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xff2B2D33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
            child: Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ==================== NOTIFICATION CARD ====================
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.info:
        return Colors.blueAccent;
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.warning:
        return Icons.error_outline;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.cancel_outlined;
    }
  }

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
              color: _getTypeColor().withOpacity(0.4),
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
                  _getTypeIcon(),
                  color: _getTypeColor(),
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
                              color: _getTypeColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            color: Color(0xff9E9FA4),
                            fontSize: 11,
                          ),
                        ),
                        if (notification.priority == NotificationPriority.high ||
                            notification.priority == NotificationPriority.critical) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: notification.priority == NotificationPriority.critical
                                  ? Colors.red
                                  : AppColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.priority == NotificationPriority.critical
                                  ? 'CRITICAL'
                                  : 'HIGH',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
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

// ==================== FILTER CHIP ====================
class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.accent).withOpacity(0.15)
              : Color(0xff2B2D33),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.accent)
                : Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (color ?? AppColors.accent) : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ==================== BADGE WIDGET ====================
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
            right: -6,
            top: -6,
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