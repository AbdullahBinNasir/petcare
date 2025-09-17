import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../theme/pet_care_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<NotificationData> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredNotifications = Provider.of<NotificationService>(
      context,
      listen: false,
    ).notifications;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterNotifications() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredNotifications = Provider.of<NotificationService>(
          context,
          listen: false,
        ).notifications;
      } else {
        _filteredNotifications = Provider.of<NotificationService>(
          context,
          listen: false,
        ).searchNotifications(_searchQuery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PetCareTheme.backgroundGradient,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllNotificationsTab(),
                  _buildUnreadNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PetCareTheme.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: PetCareTheme.primaryBeige,
                  size: 24,
                ),
              ),
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.primaryBeige,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Consumer<NotificationService>(
                builder: (context, notificationService, child) {
                  return PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: PetCareTheme.primaryBeige,
                      size: 24,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'mark_all_read':
                          await notificationService.markAllAsRead();
                          break;
                        case 'clear_all':
                          await _showClearAllDialog();
                          break;
                        case 'settings':
                          _showNotificationSettings();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all_rounded),
                            SizedBox(width: 8),
                            Text('Mark All as Read'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all_rounded),
                            SizedBox(width: 8),
                            Text('Clear All'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_rounded),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [PetCareTheme.elevatedShadow],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _filterNotifications(),
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          hintStyle: TextStyle(color: PetCareTheme.textLight, fontSize: 16),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: PetCareTheme.primaryBrown,
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterNotifications();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: PetCareTheme.textLight,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: PetCareTheme.primaryBeige.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: PetCareTheme.primaryBeige,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: PetCareTheme.primaryBrown,
        unselectedLabelColor: PetCareTheme.primaryBeige.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: [
          Tab(text: 'All (${_filteredNotifications.length})'),
          Tab(
            text:
                'Unread (${_filteredNotifications.where((n) => !n.isRead).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final notifications = _searchQuery.isEmpty
            ? notificationService.notifications
            : _filteredNotifications;

        if (notifications.isEmpty) {
          return _buildEmptyState(
            'No Notifications',
            'You don\'t have any notifications yet',
            Icons.notifications_none_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh notifications if needed
            setState(() {});
          },
          color: PetCareTheme.primaryBrown,
          backgroundColor: PetCareTheme.cardWhite,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, notificationService);
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadNotificationsTab() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final unreadNotifications = _searchQuery.isEmpty
            ? notificationService.notifications.where((n) => !n.isRead).toList()
            : _filteredNotifications.where((n) => !n.isRead).toList();

        if (unreadNotifications.isEmpty) {
          return _buildEmptyState(
            'No Unread Notifications',
            'You\'re all caught up!',
            Icons.done_all_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: PetCareTheme.primaryBrown,
          backgroundColor: PetCareTheme.cardWhite,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: unreadNotifications.length,
            itemBuilder: (context, index) {
              final notification = unreadNotifications[index];
              return _buildNotificationCard(notification, notificationService);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: PetCareTheme.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [PetCareTheme.elevatedShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PetCareTheme.primaryBrown.withOpacity(0.1),
                    PetCareTheme.lightBrown.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: PetCareTheme.primaryBrown.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PetCareTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: PetCareTheme.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationData notification,
    NotificationService notificationService,
  ) {
    final typeColor = _getNotificationTypeColor(notification.type);
    final typeIcon = _getNotificationTypeIcon(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead
              ? PetCareTheme.lightBrown.withOpacity(0.2)
              : typeColor.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: PetCareTheme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
          if (!notification.isRead)
            BoxShadow(
              color: typeColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await notificationService.markNotificationAsRead(notification.id);
            }
            // Handle navigation based on notification data
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        typeColor.withOpacity(0.2),
                        typeColor.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                // Notification content
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
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: PetCareTheme.textDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: PetCareTheme.textLight,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: PetCareTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: PetCareTheme.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getNotificationTypeName(notification.type),
                              style: TextStyle(
                                fontSize: 10,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: () async {
                    await notificationService.deleteNotification(
                      notification.id,
                    );
                    _filterNotifications();
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: PetCareTheme.textLight,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return PetCareTheme.accentGold;
      case NotificationType.healthRecord:
        return PetCareTheme.softGreen;
      case NotificationType.vaccination:
        return PetCareTheme.warmRed;
      case NotificationType.adoption:
        return PetCareTheme.warmPurple;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.reminder:
        return PetCareTheme.lightBrown;
      case NotificationType.update:
        return PetCareTheme.primaryBrown;
      case NotificationType.general:
        return PetCareTheme.textLight;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today_rounded;
      case NotificationType.healthRecord:
        return Icons.medical_services_rounded;
      case NotificationType.vaccination:
        return Icons.vaccines_rounded;
      case NotificationType.adoption:
        return Icons.pets_rounded;
      case NotificationType.emergency:
        return Icons.warning_rounded;
      case NotificationType.reminder:
        return Icons.notifications_rounded;
      case NotificationType.update:
        return Icons.system_update_rounded;
      case NotificationType.general:
        return Icons.info_rounded;
    }
  }

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'Appointment';
      case NotificationType.healthRecord:
        return 'Health';
      case NotificationType.vaccination:
        return 'Vaccination';
      case NotificationType.adoption:
        return 'Adoption';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.update:
        return 'Update';
      case NotificationType.general:
        return 'General';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // Handle navigation based on notification data
    if (notification.data != null) {
      final data = notification.data!;

      if (data['appointmentId'] != null) {
        // Navigate to appointment details
        // This would be implemented based on your navigation structure
        print('Navigate to appointment: ${data['appointmentId']}');
      } else if (data['petId'] != null) {
        // Navigate to pet profile
        print('Navigate to pet: ${data['petId']}');
      }
      // Add more navigation cases as needed
    }
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      await notificationService.clearAllNotifications();
      _filterNotifications();
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationSettingsSheet(),
    );
  }

  Widget _buildNotificationSettingsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: PetCareTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PetCareTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingTile(
                  'Enable Notifications',
                  'Receive push notifications',
                  notificationService.notificationsEnabled,
                  (value) => notificationService.setNotificationsEnabled(value),
                  Icons.notifications_rounded,
                ),
                _buildSettingTile(
                  'Sound',
                  'Play sound for notifications',
                  notificationService.soundEnabled,
                  (value) => notificationService.setSoundEnabled(value),
                  Icons.volume_up_rounded,
                ),
                _buildSettingTile(
                  'Vibration',
                  'Vibrate for notifications',
                  notificationService.vibrationEnabled,
                  (value) => notificationService.setVibrationEnabled(value),
                  Icons.vibration_rounded,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PetCareTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: PetCareTheme.primaryBrown),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PetCareTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: PetCareTheme.textLight),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: PetCareTheme.primaryBrown,
      ),
    );
  }
}
