package com.enterprise.firebase_engagement

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.firebase.messaging.FirebaseMessaging

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.enterprise.firebase_engagement/notifications"
    private val REMOTE_CONFIG_CHANNEL = "com.enterprise.firebase_engagement/remote_config"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Notification channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFCMToken" -> {
                    FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            result.success(task.result)
                        } else {
                            result.error("FCM_ERROR", "Failed to get FCM token", null)
                        }
                    }
                }
                "subscribeToTopic" -> {
                    val topic = call.argument<String>("topic") ?: ""
                    FirebaseMessaging.getInstance().subscribeToTopic(topic)
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) result.success(true)
                            else result.error("SUBSCRIBE_ERROR", "Failed to subscribe to topic", null)
                        }
                }
                "unsubscribeFromTopic" -> {
                    val topic = call.argument<String>("topic") ?: ""
                    FirebaseMessaging.getInstance().unsubscribeFromTopic(topic)
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) result.success(true)
                            else result.error("UNSUBSCRIBE_ERROR", "Failed to unsubscribe from topic", null)
                        }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        intent?.extras?.let { extras ->
            val fromNotification = extras.getString("from_notification")
            val notificationType = extras.getString("notification_type")
            // Pass notification data to Flutter via the pending result
        }
    }
}
