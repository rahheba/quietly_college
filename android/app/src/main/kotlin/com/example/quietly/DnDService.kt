package com.example.quietly

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DnDService : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    private val notificationManager: NotificationManager by lazy {
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }
    
    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }
    
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences("quietly_audio_prefs", Context.MODE_PRIVATE)
    }
    
    companion object {
        private const val CHANNEL = "app.dnd.control"
        
        // SharedPreferences keys for storing previous audio state
        private const val KEY_PREV_RINGER_MODE = "prev_ringer_mode"
        private const val KEY_PREV_RING_VOLUME = "prev_ring_volume"
        private const val KEY_PREV_NOTIFICATION_VOLUME = "prev_notification_volume"
        private const val KEY_PREV_MUSIC_VOLUME = "prev_music_volume"
        private const val KEY_PREV_DND_FILTER = "prev_dnd_filter"
        
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
                result.success(hasDndAccess())
            }
            "openDndSettings" -> {
                openDnDSettings()
                result.success(null)
            }
            "setSilent" -> {
                setSilent(result)
            }
            "restore" -> {
                restore(result)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Check if app has DND access permission
     */
    private fun hasDndAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true // No special permission needed on older Android versions
        }
    }

    /**
     * Open system settings for DND permission
     */
    private fun openDnDSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
        } else {
            Intent(Settings.ACTION_SOUND_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    /**
     * Set device to silent mode and save previous state
     */
    private fun setSilent(result: MethodChannel.Result) {
        try {
            // Start foreground service to keep app alive in background
            QuietlyForegroundService.startService(context)
            
            // Save current audio state before changing
            saveCurrentAudioState()
            
            // Set DND mode if permission granted
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!hasDndAccess()) {
                    result.error("PERMISSION_DENIED", "DnD access not granted", null)
                    return
                }
                
                // Save current DND filter
                prefs.edit().putInt(KEY_PREV_DND_FILTER, notificationManager.currentInterruptionFilter).apply()
                
                // Set to total silence
                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            }
            
            // Set ringer mode to silent
            audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
            
            // Mute all audio streams
            setStreamVolume(AudioManager.STREAM_RING, 0)
            setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0)
            setStreamVolume(AudioManager.STREAM_SYSTEM, 0)
            setStreamVolume(AudioManager.STREAM_MUSIC, 0)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SET_SILENT_FAILED", e.message, null)
        }
    }

    /**
     * Restore previous audio state
     */
    private fun restore(result: MethodChannel.Result) {
        try {
            // Restore DND filter
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDndAccess()) {
                val prevFilter = prefs.getInt(KEY_PREV_DND_FILTER, NotificationManager.INTERRUPTION_FILTER_ALL)
                notificationManager.setInterruptionFilter(prevFilter)
            }
            
            // Restore ringer mode
            val prevRingerMode = prefs.getInt(KEY_PREV_RINGER_MODE, AudioManager.RINGER_MODE_NORMAL)
            audioManager.ringerMode = prevRingerMode
            
            // Restore volume levels
            val prevRingVolume = prefs.getInt(KEY_PREV_RING_VOLUME, getMaxVolume(AudioManager.STREAM_RING) / 2)
            val prevNotificationVolume = prefs.getInt(KEY_PREV_NOTIFICATION_VOLUME, getMaxVolume(AudioManager.STREAM_NOTIFICATION) / 2)
            val prevMusicVolume = prefs.getInt(KEY_PREV_MUSIC_VOLUME, getMaxVolume(AudioManager.STREAM_MUSIC) / 2)
            
            setStreamVolume(AudioManager.STREAM_RING, prevRingVolume)
            setStreamVolume(AudioManager.STREAM_NOTIFICATION, prevNotificationVolume)
            setStreamVolume(AudioManager.STREAM_MUSIC, prevMusicVolume)
            
            // Stop foreground service
            QuietlyForegroundService.stopService(context)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("RESTORE_FAILED", e.message, null)
        }
    }

    /**
     * Save current audio state to SharedPreferences
     */
    private fun saveCurrentAudioState() {
        val editor = prefs.edit()
        
        // Save ringer mode
        editor.putInt(KEY_PREV_RINGER_MODE, audioManager.ringerMode)
        
        // Save volume levels
        editor.putInt(KEY_PREV_RING_VOLUME, getStreamVolume(AudioManager.STREAM_RING))
        editor.putInt(KEY_PREV_NOTIFICATION_VOLUME, getStreamVolume(AudioManager.STREAM_NOTIFICATION))
        editor.putInt(KEY_PREV_MUSIC_VOLUME, getStreamVolume(AudioManager.STREAM_MUSIC))
        
        editor.apply()
    }

    /**
     * Safely set stream volume
     */
    private fun setStreamVolume(streamType: Int, volume: Int) {
        try {
            val maxVolume = getMaxVolume(streamType)
            val safeVolume = volume.coerceIn(0, maxVolume)
            audioManager.setStreamVolume(streamType, safeVolume, 0)
        } catch (e: Exception) {
            // Ignore errors for streams that might not be available
        }
    }

    /**
     * Get current stream volume
     */
    private fun getStreamVolume(streamType: Int): Int {
        return try {
            audioManager.getStreamVolume(streamType)
        } catch (e: Exception) {
            0
        }
    }

    /**
     * Get maximum volume for a stream
     */
    private fun getMaxVolume(streamType: Int): Int {
        return try {
            audioManager.getStreamMaxVolume(streamType)
        } catch (e: Exception) {
            15 // Default fallback
        }
    }
}
