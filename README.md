<div align="center">

![banner](https://capsule-render.vercel.app/api?type=waving&color=FF6D00&height=200&section=header&text=Firebase%20Engagement%20Platform&fontSize=30&fontColor=white&animation=fadeIn&fontAlignY=35&desc=Flutter%20%7C%20GetX%20%7C%20Firebase%20%7C%20FCM%20%7C%20Clean%20Architecture&descAlignY=55)

[![Flutter](https://img.shields.io/badge/Flutter-3.19-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev) [![GetX](https://img.shields.io/badge/GetX-4.6-8B0000?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/get) [![Firebase](https://img.shields.io/badge/Firebase-2.x-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com) [![FCM](https://img.shields.io/badge/FCM-14.x-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://firebase.google.com/products/cloud-messaging) [![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> **Complete Firebase engagement infrastructure** — Authentication, Firestore, FCM push notifications, deep links, analytics, Crashlytics, and remote config — all orchestrated with GetX and Clean Architecture.

</div>

---

## ✨ Features

| Feature | Status |
|:--------|:------:|
| 🔐 Firebase Auth (Email/Password) | ✅ |
| 🔵 Google Sign-In | ✅ |
| 📱 OTP / Phone Auth | ✅ |
| 📂 Cloud Firestore (real-time sync) | ✅ |
| 🔔 FCM Push Notifications | ✅ |
| 🔗 Deep Links | ✅ |
| 📊 Firebase Analytics | ✅ |
| 🛡️ Crashlytics | ✅ |
| 🔀 Dynamic Links | ✅ |
| 📡 Topic Subscriptions | ✅ |
| 🌙 Background Notifications | ✅ |
| ⚙️ Remote Config | ✅ |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── di/app_bindings.dart
│   ├── routes/
│   │   ├── app_routes.dart
│   │   └── app_pages.dart
│   └── utils/deep_link_handler.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/auth_remote_datasource.dart
    │   │   └── repositories/auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── repositories/auth_repository.dart
    │   │   └── usecases/
    │   │       ├── login_with_email_usecase.dart
    │   │       ├── login_with_google_usecase.dart
    │   │       └── verify_otp_usecase.dart
    │   └── presentation/
    │       ├── bindings/auth_binding.dart
    │       ├── controllers/auth_controller.dart
    │       └── screens/login_screen.dart
    └── notification/
        ├── data/repositories/notification_repository_impl.dart
        └── services/
            ├── fcm_service.dart
            └── notification_handler.dart
services/
├── firebase_auth_service.dart
├── firestore_service.dart
└── analytics_service.dart
```

---

## 🚀 Installation

```bash
git clone https://github.com/AvinashK123-A/flutter-firebase-engagement-platform.git
cd flutter-firebase-engagement-platform
flutter pub get
# Add google-services.json (Android) and GoogleService-Info.plist (iOS)
flutter run
```

## 📦 Dependencies

```yaml
dependencies:
  get: ^4.6.6
  get_storage: ^2.1.1
  firebase_core: ^2.25.4
  firebase_auth: ^4.17.4
  cloud_firestore: ^4.15.4
  firebase_messaging: ^14.7.19
  firebase_analytics: ^10.8.9
  firebase_crashlytics: ^3.4.15
  firebase_remote_config: ^4.3.15
  flutter_local_notifications: ^16.3.2
  google_sign_in: ^6.2.1
  dartz: ^0.10.1
```

---

## 💻 Core Code

<details>
<summary><b>🔔 FcmService — Full FCM Implementation</b></summary>

```dart
// lib/services/fcm_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:get/get.dart';
import '../core/routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationHandler.handleBackground(message);
}

@singleton
class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local;
  final _controller = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForeground => _controller.stream;

  FcmService(this._local);

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const channel = AndroidNotificationChannel(
      'high_importance', 'High Importance',
      importance: Importance.high);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onTap(initial);
  }

  void _onForeground(RemoteMessage msg) {
    _controller.add(msg);
    _showLocal(msg);
  }

  void _onTap(RemoteMessage msg) {
    final deepLink = msg.data['deep_link'] as String?;
    if (deepLink != null) Get.toNamed(deepLink);
  }

  Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification; if (n == null) return;
    await _local.show(n.hashCode, n.title, n.body,
      const NotificationDetails(android: AndroidNotificationDetails(
        'high_importance', 'High Importance',
        importance: Importance.high, priority: Priority.high)),
      payload: msg.data['deep_link']);
  }

  Future<String?> getToken() => _fcm.getToken();
  Future<void> subscribeToTopic(String t) => _fcm.subscribeToTopic(t);
  Future<void> unsubscribeFromTopic(String t) => _fcm.unsubscribeFromTopic(t);
  void dispose() => _controller.close();
}
```

</details>

<details>
<summary><b>🔐 AuthController — GetX Controller</b></summary>

```dart
// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:get/get.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final LoginWithEmailUseCase _loginEmail;
  final LoginWithGoogleUseCase _loginGoogle;
  final VerifyOtpUseCase _verifyOtp;

  AuthController(this._loginEmail, this._loginGoogle, this._verifyOtp);

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final isAuthenticated = false.obs;

  Future<void> loginWithEmail(String email, String password) async {
    isLoading.value = true; errorMessage.value = null;
    final result = await _loginEmail(email: email, password: password);
    result.fold(
      (f) => errorMessage.value = f.message,
      (_) { isAuthenticated.value = true; Get.offAllNamed(AppRoutes.home); });
    isLoading.value = false;
  }

  Future<void> loginWithGoogle() async {
    isLoading.value = true; errorMessage.value = null;
    final result = await _loginGoogle();
    result.fold(
      (f) => errorMessage.value = f.message,
      (_) { isAuthenticated.value = true; Get.offAllNamed(AppRoutes.home); });
    isLoading.value = false;
  }

  Future<void> verifyOtp(String verificationId, String otp) async {
    isLoading.value = true; errorMessage.value = null;
    final result = await _verifyOtp(verificationId: verificationId, otp: otp);
    result.fold(
      (f) => errorMessage.value = f.message,
      (_) { isAuthenticated.value = true; Get.offAllNamed(AppRoutes.home); });
    isLoading.value = false;
  }

  Future<void> signOut() async {
    isAuthenticated.value = false;
    Get.offAllNamed(AppRoutes.login);
  }
}
```

</details>

<details>
<summary><b>💉 AuthBinding — GetX Dependency Injection</b></summary>

```dart
// lib/features/auth/presentation/bindings/auth_binding.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
    Get.lazyPut<AuthRepositoryImpl>(
        () => AuthRepositoryImpl(Get.find()));
    Get.lazyPut(() => LoginWithEmailUseCase(Get.find()));
    Get.lazyPut(() => LoginWithGoogleUseCase(Get.find()));
    Get.lazyPut(() => VerifyOtpUseCase(Get.find()));
    Get.lazyPut<AuthController>(
        () => AuthController(Get.find(), Get.find(), Get.find()));
  }
}
```

</details>

---

## 🗺️ Roadmap

- [x] Firebase Auth (Email, Google, OTP)
- [x] FCM push notifications (all states)
- [x] Deep linking + Dynamic links
- [x] Analytics + Crashlytics
- [x] Remote Config feature flags
- [ ] In-App Messaging campaigns
- [ ] A/B Testing via Remote Config
- [ ] Anonymous auth + upgrade flow

---

## 📄 License

MIT License — see [LICENSE](LICENSE).

---

<div align="center">

**Built with ❤️ by [Avinash Reddy](https://github.com/AvinashK123-A)**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/avinash-reddy-0826b0222/)

![footer](https://capsule-render.vercel.app/api?type=waving&color=FF6D00&height=100&section=footer)

</div>
