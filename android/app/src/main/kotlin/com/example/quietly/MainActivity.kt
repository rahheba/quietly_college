package com.example.quietly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val EXTRA_FROM_NOTIFICATION = "from_notification"
        private const val CHANNEL_BACKGROUND = "app.quietly.background"
    }

    private var flutterEngineRef: FlutterEngine? = null
    private var backgroundChannel: MethodChannel? = null
    private var geoMuteChannel: MethodChannel? = null

    private val logReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val logMessage = intent?.getStringExtra("log") ?: return
            geoMuteChannel?.invokeMethod("onLog", logMessage)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DnDService.registerWith(flutterEngine)
        flutterEngineRef = flutterEngine
        backgroundChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BACKGROUND)

        // Geo Mute Channel
        geoMuteChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "geo_mute_channel")
        geoMuteChannel?.setMethodCallHandler { call, result ->
                if (call.method == "startMonitoring") {
                    val latitude = call.argument<Double>("latitude") ?: 0.0
                    val longitude = call.argument<Double>("longitude") ?: 0.0

                    val serviceIntent = Intent(this, GeoMuteForegroundService::class.java).apply {
                        putExtra("latitude", latitude)
                        putExtra("longitude", longitude)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(null)
                } else if (call.method == "stopMonitoring") {
                    stopService(Intent(this, GeoMuteForegroundService::class.java))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyFlutterActivateBackground()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(logReceiver, IntentFilter("GeoMuteLogBroadcast"), RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(logReceiver, IntentFilter("GeoMuteLogBroadcast"))
        }

        // After Flutter is ready, notify if we were launched from notification
        window.decorView.post {
            window.decorView.postDelayed({
                if (intent?.getBooleanExtra(EXTRA_FROM_NOTIFICATION, false) == true) {
                    notifyFlutterActivateBackground()
                }
            }, 400)
        }
    }

    private fun notifyFlutterActivateBackground() {
        if (intent?.getBooleanExtra(EXTRA_FROM_NOTIFICATION, false) != true) return
        try {
            backgroundChannel?.invokeMethod("activateBackground", null)
        } catch (_: Exception) { }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(logReceiver)
    }
}
