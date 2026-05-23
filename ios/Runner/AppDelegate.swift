import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import FirebaseDynamicLinks
import FirebaseInAppMessaging
import FirebaseRemoteConfig
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private let kDeepLinkChannel = "com.avinash.firebase.engagement/deeplink"
    private let kFCMChannel = "com.avinash.firebase.engagement/fcm"
    private let kRemoteConfigChannel = "com.avinash.firebase.engagement/remote_config"

    private var deepLinkChannel: FlutterMethodChannel?
    private var fcmChannel: FlutterMethodChannel?
    private var pendingDeepLink: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        if let controller = window?.rootViewController as? FlutterViewController {
            setupDeepLinkChannel(controller: controller)
            setupFCMChannel(controller: controller)
            setupRemoteConfigChannel(controller: controller)
        }

        GeneratedPluginRegistrant.register(with: self)

        // Configure notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
        application.registerForRemoteNotifications()

        // Setup Firebase In-App Messaging
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = false

        // Fetch and activate Remote Config at startup
        Task { await fetchRemoteConfig() }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - URL Handling

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Firebase Dynamic Links
        if DynamicLinks.dynamicLinks().handleUniversalLink(url) { return true }
        deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
        return true
    }

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if let url = userActivity.webpageURL {
            // Handle Firebase Dynamic Link
            let handled = DynamicLinks.dynamicLinks().handleUniversalLink(url) { [weak self] dynamicLink, error in
                guard error == nil, let deepLinkURL = dynamicLink?.url else { return }
                self?.deepLinkChannel?.invokeMethod("onDynamicLink", arguments: deepLinkURL.absoluteString)
            }
            if !handled {
                deepLinkChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
            }
            return true
        }
        return false
    }

    // MARK: - Push Notifications

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // MARK: - Firebase Remote Config

    private func fetchRemoteConfig() async {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")

        do {
            let status = try await remoteConfig.fetch()
            if status == .success {
                try await remoteConfig.activate()
                NSLog("[AppDelegate] Remote config fetched and activated")
                remoteConfigChannel?.invokeMethod("onRemoteConfigUpdated", arguments: nil)
            }
        } catch {
            NSLog("[AppDelegate] Remote config fetch error: %@", error.localizedDescription)
        }
    }

    private var remoteConfigChannel: FlutterMethodChannel?

    // MARK: - Channel Setup

    private func setupDeepLinkChannel(controller: FlutterViewController) {
        deepLinkChannel = FlutterMethodChannel(
            name: kDeepLinkChannel,
            binaryMessenger: controller.binaryMessenger
        )
        deepLinkChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getInitialLink":
                result(self?.pendingDeepLink)
                self?.pendingDeepLink = nil
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupFCMChannel(controller: FlutterViewController) {
        fcmChannel = FlutterMethodChannel(
            name: kFCMChannel,
            binaryMessenger: controller.binaryMessenger
        )
        fcmChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "getFCMToken":
                Messaging.messaging().token { token, error in
                    if let error = error {
                        result(FlutterError(code: "FCM_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(token)
                    }
                }
            case "subscribeToTopic":
                guard let args = call.arguments as? [String: Any],
                      let topic = args["topic"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                Messaging.messaging().subscribe(toTopic: topic) { error in
                    result(error == nil)
                }
            case "unsubscribeFromTopic":
                guard let args = call.arguments as? [String: Any],
                      let topic = args["topic"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                    result(error == nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func setupRemoteConfigChannel(controller: FlutterViewController) {
        remoteConfigChannel = FlutterMethodChannel(
            name: kRemoteConfigChannel,
            binaryMessenger: controller.binaryMessenger
        )
        remoteConfigChannel?.setMethodCallHandler { call, result in
            let remoteConfig = RemoteConfig.remoteConfig()
            switch call.method {
            case "getString":
                let key = (call.arguments as? [String: Any])?["key"] as? String ?? ""
                result(remoteConfig[key].stringValue)
            case "getBool":
                let key = (call.arguments as? [String: Any])?["key"] as? String ?? ""
                result(remoteConfig[key].boolValue)
            case "getInt":
                let key = (call.arguments as? [String: Any])?["key"] as? String ?? ""
                result(remoteConfig[key].numberValue.intValue)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let link = userInfo["deep_link"] as? String {
            deepLinkChannel?.invokeMethod("onNotificationTap", arguments: link)
        }
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        NSLog("[AppDelegate] FCM Token refreshed")
        fcmChannel?.invokeMethod("onTokenRefresh", arguments: fcmToken)
    }
}
