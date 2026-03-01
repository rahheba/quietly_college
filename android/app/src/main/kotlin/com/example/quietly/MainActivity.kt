package com.example.quietly

import android.content.Intent
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DnDService.registerWith(flutterEngine)
        flutterEngineRef = flutterEngine
        backgroundChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BACKGROUND)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyFlutterActivateBackground()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
}
