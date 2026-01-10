package com.example.quietly

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*

class DnDService : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var isServiceRunning = false
    private val notificationManager: NotificationManager by lazy {
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }
    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }
    
    private val CHANNEL_ID = "DnDServiceChannel"
    private val NOTIFICATION_ID = 1

    companion object {
        private const val CHANNEL = "app.dnd.control"
        
        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine) {
            val plugin = DnDService()
            flutterEngine.plugins.add(plugin)
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasDndAccess" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    result.success(notificationManager.isNotificationPolicyAccessGranted)
                } else {
                    result.success(true)
                }
            }
            "openDndSettings" -> {
                openDnDSettings()
                result.success(null)
            }
            "setSilent" -> {
                try {
                    startForegroundService()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!notificationManager.isNotificationPolicyAccessGranted) {
                            result.error("PERMISSION_DENIED", "DnD access not granted", null)
                            return
                        }
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    }
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                    audioManager.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
                    audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SET_SILENT_FAILED", e.message, null)
                }
            }
            "restore" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && 
                        notificationManager.isNotificationPolicyAccessGranted) {
                        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    stopForegroundService()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("RESTORE_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun startForegroundService() {
        if (isServiceRunning) return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Quietly DND Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Running in background to maintain DND mode"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notificationIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Quietly is Active")
            .setContentText("Do Not Disturb mode is enabled")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        (context as? android.app.Service)?.startForeground(NOTIFICATION_ID, notification)
        isServiceRunning = true
    }

    private fun stopForegroundService() {
        if (!isServiceRunning) return
        
        try {
            (context as? android.app.Service)?.stopForeground(true)
            (context as? android.app.Service)?.stopSelf()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isServiceRunning = false
        }
    }

    private fun openDnDSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
        } else {
            Intent(Settings.ACTION_SOUND_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}