package com.example.quietly

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class QuietlyForegroundService : Service() {

    private val CHANNEL_ID = "QuietlyServiceChannel"
    private val NOTIFICATION_ID = 1001

    companion object {
        private var isRunning = false

        fun isServiceRunning(): Boolean = isRunning

        fun startService(context: Context) {
            try {
                val intent = Intent(context, QuietlyForegroundService::class.java).apply {
                    setPackage(context.packageName)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                // Fallback for older devices or edge cases
                try {
                    context.startService(Intent(context, QuietlyForegroundService::class.java))
                } catch (_: Exception) { }
            }
        }

        fun stopService(context: Context) {
            try {
                val intent = Intent(context, QuietlyForegroundService::class.java)
                context.stopService(intent)
            } catch (_: Exception) { }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val notification = createNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            try {
                startForeground(NOTIFICATION_ID, createNotification())
            } catch (_: Exception) { }
        }
        isRunning = true
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Quietly Background Service",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Keeps Quietly running in background for geofencing (300m radius)"
                    setShowBadge(false)
                }
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            } catch (_: Exception) { }
        }
    }

    private fun createNotification(): Notification {
        // Intent to open app when user taps notification - brings app to foreground
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        // PendingIntent flags: FLAG_IMMUTABLE required on Android 12+ (API 31), not available below API 23
        val pendingIntentFlags = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else -> PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            pendingIntentFlags
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Quietly is Active")
            .setContentText("Inside 300m: muted • Outside: unmuted • Tap to open")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
