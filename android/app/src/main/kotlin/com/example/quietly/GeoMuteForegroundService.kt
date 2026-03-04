package com.example.quietly

import android.app.*
import android.content.Intent
import android.location.Location
import android.media.AudioManager
import android.os.IBinder
import android.util.Log // Added for debugging
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class GeoMuteForegroundService : Service() {

    private lateinit var fusedClient: FusedLocationProviderClient
    private var targetLat = 0.0
    private var targetLng = 0.0
    private var isMuted = false
    private var insideCounter = 0

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        targetLat = intent?.getDoubleExtra("latitude", 0.0) ?: 0.0
        targetLng = intent?.getDoubleExtra("longitude", 0.0) ?: 0.0

        startForegroundService()
        startLocationUpdates()

        return START_STICKY
    }

    private fun startForegroundService() {
        val channelId = "geo_mute_channel"

        val channel = NotificationChannel(
            channelId,
            "Geo Mute Service",
            NotificationManager.IMPORTANCE_LOW
        )

        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Geo Mute Running")
            .setContentText("Monitoring location")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun startLocationUpdates() {

        fusedClient = LocationServices.getFusedLocationProviderClient(this)

        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            2000
        ).setMinUpdateIntervalMillis(1000)
         .build()

        try {
            fusedClient.requestLocationUpdates(
                request,
                locationCallback,
                mainLooper
            )
        } catch (e: SecurityException) {
            // Permission denied
        }
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return

            val logMsg = "Live Location Update: Lat ${location.latitude}, Lng ${location.longitude}, Accuracy ${location.accuracy}m"
            Log.d("GeoMute", logMsg)
            sendLogToFlutter(logMsg)

            // Removed strict accuracy filter to ensure it works even on bad indoor GPS
            checkDistance(location)
        }
    }

    private fun checkDistance(location: Location) {
        val results = FloatArray(1)

        Location.distanceBetween(
            location.latitude,
            location.longitude,
            targetLat,
            targetLng,
            results
        )

        val distance = results[0]
        val distMsg = "Distance to target ($targetLat, $targetLng): $distance meters"
        Log.d("GeoMute", distMsg)
        sendLogToFlutter(distMsg)

        // Increased radius to 50 meters because GPS drift is common
        if (distance <= 50f) {
            insideCounter++
            val inMsg = "Inside zone! Counter: $insideCounter"
            Log.d("GeoMute", inMsg)
            sendLogToFlutter(inMsg)
            
            if (insideCounter >= 2 && !isMuted) {
                mutePhone()
                isMuted = true
            }
        } else {
            insideCounter = 0
            if (isMuted) {
                val outMsg = "Outside zone! Counter reset, unmuting"
                Log.d("GeoMute", outMsg)
                sendLogToFlutter(outMsg)
                unmutePhone()
                isMuted = false
            }
        }
    }

    private fun mutePhone() {
        Log.d("GeoMute", "Muting phone -> RINGER_MODE_SILENT")
        sendLogToFlutter("ACTION: Muting phone -> RINGER_MODE_SILENT")
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
    }

    private fun unmutePhone() {
        Log.d("GeoMute", "Unmuting phone -> RINGER_MODE_NORMAL")
        sendLogToFlutter("ACTION: Unmuting phone -> RINGER_MODE_NORMAL")
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
    }

    private fun sendLogToFlutter(message: String) {
        val intent = Intent("GeoMuteLogBroadcast")
        intent.putExtra("log", message)
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::fusedClient.isInitialized) {
            fusedClient.removeLocationUpdates(locationCallback)
        }
        if (isMuted) {
            unmutePhone()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
