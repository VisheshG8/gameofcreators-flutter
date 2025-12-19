package com.gameofcreators.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val data = intent.data
            if (data != null) {
                Log.d("MainActivity", "Deep link received: $data")
                // The app_links plugin will handle this via getInitialLink/uriLinkStream
            }
        }
    }

    /**
     * Create notification channel for heads-up notifications
     * CRITICAL: This channel ID must match:
     * 1. OneSignal Dashboard channel name (NOT the UUID)
     * 2. The android_channel_id in notification_service.dart
     * 3. The android_channel_id parameter when sending notifications via API
     */
    private fun createNotificationChannel() {
        // Only create channel on Android 8.0+ (API 26+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create multiple channels to ensure OneSignal uses the right one
            // IMPORTANT: Using new channel ID to bypass any existing channel with wrong importance
            val channels = listOf(
                // Primary channel - NEW ID to force fresh creation with correct importance
                Triple("game_of_creators_headsup_v2", "Important Updates", "Critical notifications that appear as pop-ups on screen"),
                // Fallback: Override OneSignal's default channel
                Triple("fcm_fallback_notification_channel", "Default", "Default notification channel"),
                Triple("Miscellaneous", "Miscellaneous", "Miscellaneous notifications")
            )

            Log.d("MainActivity", "======================================")
            Log.d("MainActivity", "🔧 Creating Notification Channels...")

            channels.forEach { (channelId, channelName, channelDescription) ->
                // Check if channel already exists
                val existingChannel = notificationManager.getNotificationChannel(channelId)

                if (existingChannel != null) {
                    Log.d("MainActivity", "⚠️ Channel already exists: $channelId")
                    Log.d("MainActivity", "   - Current Importance: ${existingChannel.importance}")
                    Log.d("MainActivity", "   - Required Importance: ${NotificationManager.IMPORTANCE_HIGH}")

                    if (existingChannel.importance < NotificationManager.IMPORTANCE_HIGH) {
                        Log.d("MainActivity", "❌ PROBLEM: Channel importance is too low!")
                        Log.d("MainActivity", "   Solution: Uninstall app and reinstall to recreate channel with correct importance")
                        Log.d("MainActivity", "   Note: Channel importance cannot be changed programmatically once created")
                    }
                }

                // Use IMPORTANCE_HIGH for heads-up notifications (per Android docs)
                // IMPORTANCE_HIGH is the correct level for time-sensitive heads-up notifications
                val importance = NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(channelId, channelName, importance).apply {
                    description = channelDescription

                    // Enable all notification features for maximum visibility
                    setShowBadge(true)
                    enableLights(true)
                    lightColor = android.graphics.Color.BLUE
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 200, 500)

                    // CRITICAL: Lock screen visibility for heads-up display
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC

                    // Set sound to default notification sound
                    val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                    setSound(defaultSoundUri, audioAttributes)
                }

                // Register the channel with the system
                notificationManager.createNotificationChannel(channel)

                // DIAGNOSTIC: Verify channel was created and log its properties
                val createdChannel = notificationManager.getNotificationChannel(channelId)
                Log.d("MainActivity", "✅ Channel: $channelId")
                Log.d("MainActivity", "   - Name: ${createdChannel?.name}")
                Log.d("MainActivity", "   - Importance: ${createdChannel?.importance}")
                Log.d("MainActivity", "   - Can bypass DND: ${createdChannel?.canBypassDnd()}")
            }

            Log.d("MainActivity", "======================================")
        } else {
            Log.d("MainActivity", "⚠️ Android version < 8.0 - Notification channels not supported")
        }
    }
}
