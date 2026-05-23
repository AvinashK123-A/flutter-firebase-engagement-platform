import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../storage/local_storage.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_as_read_usecase.dart';
import '../../features/notifications/domain/usecases/subscribe_topic_usecase.dart';
import '../../features/notifications/presentation/controllers/notification_controller.dart';
import '../../features/remote_config/data/repositories/remote_config_repository_impl.dart';
import '../../features/remote_config/domain/repositories/remote_config_repository.dart';
import '../../features/remote_config/presentation/controllers/remote_config_controller.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/presentation/controllers/analytics_controller.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

Future<void> configureDependencies() async {
  // Firebase services
  Get.lazyPut<FirebaseMessaging>(() => FirebaseMessaging.instance);
  Get.lazyPut<FirebaseRemoteConfig>(() => FirebaseRemoteConfig.instance);
  Get.lazyPut<FirebaseAnalytics>(() => FirebaseAnalytics.instance);
  Get.lazyPut<FirebaseCrashlytics>(() => FirebaseCrashlytics.instance);
  Get.lazyPut<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Network
  final dioClient = DioClient();
  Get.lazyPut<DioClient>(() => dioClient);
  Get.lazyPut<Dio>(() => dioClient.dio);

  // Storage
  Get.lazyPut<LocalStorage>(() => LocalStorageImpl());

  // Auth
  Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl());
  Get.lazyPut<AuthController>(() => AuthController(
    authRepository: Get.find<AuthRepository>(),
  ));

  // Notifications
  Get.lazyPut<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      firestore: Get.find<FirebaseFirestore>(),
      messaging: Get.find<FirebaseMessaging>(),
    ),
  );
  Get.lazyPut<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: Get.find<NotificationRemoteDataSource>(),
    ),
  );
  Get.lazyPut(() => GetNotificationsUseCase(Get.find<NotificationRepository>()));
  Get.lazyPut(() => MarkAsReadUseCase(Get.find<NotificationRepository>()));
  Get.lazyPut(() => SubscribeTopicUseCase(Get.find<NotificationRepository>()));
  Get.lazyPut<NotificationController>(() => NotificationController(
    getNotifications: Get.find<GetNotificationsUseCase>(),
    markAsRead: Get.find<MarkAsReadUseCase>(),
    subscribeTopic: Get.find<SubscribeTopicUseCase>(),
    messaging: Get.find<FirebaseMessaging>(),
  ));

  // Remote Config
  Get.lazyPut<RemoteConfigRepository>(
    () => RemoteConfigRepositoryImpl(
      remoteConfig: Get.find<FirebaseRemoteConfig>(),
    ),
  );
  Get.lazyPut<RemoteConfigController>(() => RemoteConfigController(
    repository: Get.find<RemoteConfigRepository>(),
  ));

  // Analytics
  Get.lazyPut<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      analytics: Get.find<FirebaseAnalytics>(),
      crashlytics: Get.find<FirebaseCrashlytics>(),
    ),
  );
  Get.lazyPut<AnalyticsController>(() => AnalyticsController(
    repository: Get.find<AnalyticsRepository>(),
  ));
}
