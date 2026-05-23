import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/subscribe_topic_usecase.dart';
import '../../../../core/services/notification_service.dart';

class NotificationController extends GetxController {
  final GetNotificationsUseCase getNotifications;
  final MarkAsReadUseCase markAsRead;
  final SubscribeTopicUseCase subscribeTopic;
  final FirebaseMessaging messaging;

  NotificationController({
    required this.getNotifications,
    required this.markAsRead,
    required this.subscribeTopic,
    required this.messaging,
  });

  final RxList<NotificationEntity> notifications = <NotificationEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt unreadCount = 0.obs;
  final RxString fcmToken = ''.obs;
  final RxList<String> subscribedTopics = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFCM();
    _listenToForegroundMessages();
    _listenToNotificationTaps();
    loadNotifications();
  }

  Future<void> _initializeFCM() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          fcmToken.value = token;
          await _updateTokenOnServer(token);
        }

        messaging.onTokenRefresh.listen((newToken) {
          fcmToken.value = newToken;
          _updateTokenOnServer(newToken);
        });
      }
    } catch (e) {
      errorMessage.value = 'Failed to initialize notifications: $e';
    }
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = _remoteMessageToEntity(message);
      notifications.insert(0, notification);
      unreadCount.value++;
      NotificationService.showLocalNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.body,
        payload: notification.data.toString(),
      );
    });
  }

  void _listenToNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(_remoteMessageToEntity(message));
    });
  }

  Future<void> loadNotifications({int page = 1}) async {
    isLoading.value = true;
    hasError.value = false;

    final result = await getNotifications(GetNotificationsParams(page: page));
    result.fold(
      (failure) {
        hasError.value = true;
        errorMessage.value = failure.message;
      },
      (items) {
        if (page == 1) {
          notifications.assignAll(items);
        } else {
          notifications.addAll(items);
        }
        unreadCount.value = items.where((n) => !n.isRead).length;
      },
    );

    isLoading.value = false;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final result = await markAsRead(MarkAsReadParams(notificationId: notificationId));
    result.fold(
      (failure) => Get.snackbar('Error', failure.message, snackPosition: SnackPosition.BOTTOM),
      (_) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final updated = notifications[index].copyWith(isRead: true);
          notifications[index] = updated;
          if (unreadCount.value > 0) unreadCount.value--;
        }
      },
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    final result = await subscribeTopic(SubscribeTopicParams(topic: topic));
    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to subscribe: ${failure.message}', snackPosition: SnackPosition.BOTTOM),
      (_) {
        if (!subscribedTopics.contains(topic)) {
          subscribedTopics.add(topic);
        }
        Get.snackbar('Success', 'Subscribed to $topic', snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await messaging.unsubscribeFromTopic(topic);
    subscribedTopics.remove(topic);
  }

  void _handleNotificationTap(NotificationEntity notification) {
    markNotificationAsRead(notification.id);
    final route = notification.data['route'] as String?;
    if (route != null) {
      Get.toNamed(route, arguments: notification.data);
    } else {
      Get.toNamed('/notifications');
    }
  }

  Future<void> _updateTokenOnServer(String token) async {
    // API call to update FCM token
  }

  NotificationEntity _remoteMessageToEntity(RemoteMessage message) {
    return NotificationEntity(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      isRead: false,
      createdAt: message.sentTime ?? DateTime.now(),
      data: message.data,
    );
  }

  Future<void> markAllAsRead() async {
    for (final notification in notifications.where((n) => !n.isRead)) {
      await markNotificationAsRead(notification.id);
    }
  }

  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }
}
