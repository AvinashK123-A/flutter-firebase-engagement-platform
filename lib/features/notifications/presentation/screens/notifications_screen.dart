import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_chips.dart';

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.surface,
        actions: [
          Obx(() => controller.unreadCount.value > 0
            ? TextButton(
                onPressed: controller.markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(color: AppColors.primary),
                ),
              )
            : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed('/notification-settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadNotifications(),
        color: AppColors.primary,
        child: Column(
          children: [
            Obx(() => NotificationFilterChips(
              unreadCount: controller.unreadCount.value,
              onFilterChanged: (filter) {},
            )),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.notifications.isEmpty) {
                  return const ShimmerLoading();
                }
                if (controller.hasError.value) {
                  return AppErrorWidget(
                    message: controller.errorMessage.value,
                    onRetry: () => controller.loadNotifications(),
                  );
                }
                if (controller.notifications.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.notifications_off_outlined,
                    title: 'No Notifications',
                    subtitle: 'You are all caught up!',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => controller.markNotificationAsRead(notification.id),
                      child: NotificationCard(
                        notification: notification,
                        onTap: () => controller.markNotificationAsRead(notification.id),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
