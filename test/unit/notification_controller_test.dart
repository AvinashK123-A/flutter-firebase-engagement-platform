import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_firebase_engagement_platform/core/errors/failures.dart';
import 'package:flutter_firebase_engagement_platform/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_firebase_engagement_platform/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:flutter_firebase_engagement_platform/features/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:flutter_firebase_engagement_platform/features/notifications/domain/usecases/subscribe_topic_usecase.dart';
import 'package:flutter_firebase_engagement_platform/features/notifications/presentation/controllers/notification_controller.dart';

import 'notification_controller_test.mocks.dart';

@GenerateMocks([GetNotificationsUseCase, MarkAsReadUseCase, SubscribeTopicUseCase, FirebaseMessaging])
void main() {
  late NotificationController controller;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockMarkAsReadUseCase mockMarkAsRead;
  late MockSubscribeTopicUseCase mockSubscribeTopic;
  late MockFirebaseMessaging mockMessaging;

  final tNotification = NotificationEntity(
    id: 'notif_001',
    title: 'Test Notification',
    body: 'This is a test notification',
    type: 'general',
    isRead: false,
    createdAt: DateTime(2024, 1, 1),
    data: {},
  );

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockMarkAsRead = MockMarkAsReadUseCase();
    mockSubscribeTopic = MockSubscribeTopicUseCase();
    mockMessaging = MockFirebaseMessaging();

    when(mockMessaging.requestPermission(
      alert: anyNamed('alert'),
      badge: anyNamed('badge'),
      sound: anyNamed('sound'),
      provisional: anyNamed('provisional'),
      announcement: anyNamed('announcement'),
      carPlay: anyNamed('carPlay'),
      criticalAlert: anyNamed('criticalAlert'),
    )).thenAnswer((_) async => const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
    ));
    when(mockMessaging.getToken()).thenAnswer((_) async => 'test_fcm_token');
    when(mockMessaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());

    when(mockGetNotifications(any)).thenAnswer(
      (_) async => Right([tNotification]),
    );

    Get.testMode = true;
    controller = NotificationController(
      getNotifications: mockGetNotifications,
      markAsRead: mockMarkAsRead,
      subscribeTopic: mockSubscribeTopic,
      messaging: mockMessaging,
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('loadNotifications', () {
    test('should load notifications successfully', () async {
      when(mockGetNotifications(any)).thenAnswer(
        (_) async => Right([tNotification]),
      );

      await controller.loadNotifications();

      expect(controller.notifications, [tNotification]);
      expect(controller.isLoading.value, false);
      expect(controller.hasError.value, false);
    });

    test('should set error state on failure', () async {
      when(mockGetNotifications(any)).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Network error')),
      );

      await controller.loadNotifications();

      expect(controller.hasError.value, true);
      expect(controller.errorMessage.value, 'Network error');
      expect(controller.isLoading.value, false);
    });
  });

  group('markNotificationAsRead', () {
    test('should mark notification as read', () async {
      controller.notifications.add(tNotification);
      when(mockMarkAsRead(any)).thenAnswer((_) async => const Right(null));

      await controller.markNotificationAsRead(tNotification.id);

      expect(controller.notifications.first.isRead, true);
    });
  });

  group('subscribeToTopic', () {
    test('should subscribe to topic successfully', () async {
      when(mockSubscribeTopic(any)).thenAnswer((_) async => const Right(null));

      await controller.subscribeToTopic('promotions');

      expect(controller.subscribedTopics, contains('promotions'));
    });
  });
}
