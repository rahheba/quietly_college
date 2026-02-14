# How the Geofencing Auto-Mute System Works

## Overview
Your app automatically enables Do Not Disturb (DND) mode when the device enters a specified geographic location (geofence) and disables it when the device exits that location.

---

## 🎯 Core Functionality

### **When Device ENTERS the Geofence:**
1. **Location Detection**: The app continuously monitors your GPS location
2. **Distance Calculation**: Calculates distance from target coordinates using the Haversine formula
3. **Entry Detection**: When distance ≤ 40 meters (configurable radius)
4. **State Change**: Detects transition from "outside" to "inside"
5. **Automatic Actions**:
   - ✅ Saves current audio settings (volume levels, ringer mode)
   - ✅ Starts foreground service (keeps app alive in background)
   - ✅ Enables Do Not Disturb mode (total silence)
   - ✅ Sets ringer mode to SILENT
   - ✅ Mutes all audio streams (ring, notification, system, music)
   - ✅ Shows persistent notification ("Quietly is Active")
   - ✅ Saves "inside" state to persist across app restarts

### **When Device EXITS the Geofence:**
1. **Exit Detection**: When distance > 40 meters
2. **State Change**: Detects transition from "inside" to "outside"
3. **Automatic Actions**:
   - ✅ Restores previous DND filter
   - ✅ Restores previous ringer mode
   - ✅ Restores previous volume levels (exactly as they were)
   - ✅ Stops foreground service
   - ✅ Removes notification
   - ✅ Saves "outside" state

---

## 🔧 Technical Implementation

### **1. Geofencing Service (`map_service.dart`)**

**Key Features:**
- **Continuous Location Tracking**: Updates every 10 meters
- **High Accuracy GPS**: Uses `LocationAccuracy.high`
- **Debouncing**: Prevents rapid mute/unmute cycles (10-second minimum between triggers)
- **State Persistence**: Remembers if you're inside/outside even after app restart
- **Error Recovery**: Automatically restarts tracking if location service fails
- **Memory Management**: Properly cancels streams to prevent leaks

**Target Location (Configurable):**
```dart
targetLat = 10.9756321;  // Latitude
targetLng = 76.2172223;  // Longitude
targetRadiusMeters = 40.0;  // 40-meter radius
```

**How Distance is Calculated:**
Uses the Haversine formula to calculate the great-circle distance between two points on Earth:
```dart
double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0; // Earth radius in meters
  // ... Haversine calculation
  return R * c;
}
```

### **2. DND Service (`DnDService.kt` - Android)**

**Capabilities:**
- **Permission Checking**: Verifies DND access before attempting changes
- **State Preservation**: Saves all audio settings before muting
- **Safe Volume Control**: Bounds-checks all volume changes
- **Foreground Service Integration**: Keeps app alive in background

**Audio Settings Saved:**
- Ringer mode (Normal/Vibrate/Silent)
- Ring volume
- Notification volume
- Music volume
- DND filter mode

### **3. Foreground Service (`QuietlyForegroundService.kt`)**

**Purpose:**
- Keeps the app running in the background
- Prevents Android from killing the location tracking
- Shows persistent notification to user
- Uses `START_STICKY` to restart if killed by system

**Notification:**
- Title: "Quietly is Active"
- Content: "Monitoring location for automatic mute"
- Low priority (non-intrusive)
- Ongoing (cannot be swiped away)

---

## 📱 Required Permissions

### **Location Permissions:**
1. **ACCESS_FINE_LOCATION** - For precise GPS coordinates
2. **ACCESS_COARSE_LOCATION** - Fallback for approximate location
3. **ACCESS_BACKGROUND_LOCATION** - Critical for tracking when app is closed

⚠️ **Important**: On Android 10+, user must select **"Allow all the time"** for background tracking to work.

### **Audio Permissions:**
1. **ACCESS_NOTIFICATION_POLICY** - To control Do Not Disturb mode
2. **MODIFY_AUDIO_SETTINGS** - To change volume levels

### **Service Permissions:**
1. **FOREGROUND_SERVICE** - To run background service
2. **FOREGROUND_SERVICE_LOCATION** - Specific to location-based foreground service
3. **WAKE_LOCK** - To keep device awake for location updates

---

## 🔄 App Lifecycle

### **App Startup:**
```
1. Initialize Firebase
2. Initialize GeoMute service
3. Load saved target location from SharedPreferences
4. Load saved inside/outside state
5. Check location permissions
6. Start location tracking
7. Begin monitoring geofence
```

### **Background Operation:**
```
1. Foreground service keeps app alive
2. Location updates continue every 10 meters
3. Distance checked against target
4. Entry/exit events trigger mute/unmute
5. State saved after each change
```

### **App Restart:**
```
1. Load previous state from SharedPreferences
2. Resume tracking from last known state
3. No duplicate mute/unmute triggers
```

---

## 🛡️ Safety Features

### **1. Debouncing**
- Prevents rapid mute/unmute cycles
- Minimum 10 seconds between triggers
- Protects against GPS fluctuations near geofence boundary

### **2. State Persistence**
- Saves current state to SharedPreferences
- Prevents duplicate actions after app restart
- Remembers if you're inside or outside geofence

### **3. Error Handling**
- Catches location stream errors
- Auto-restarts tracking after 5-second delay
- Graceful fallback if permissions denied
- Safe volume setting with bounds checking

### **4. Permission Validation**
- Checks permissions before every action
- Prompts user to grant permissions if missing
- Opens settings if permissions denied

---

## 📊 Logging & Debugging

The app provides extensive logging for troubleshooting:

```
Starting geofence tracking...
Target: (10.9756321, 76.2172223), Radius: 40.0 m
Current position: (10.9756500, 76.2172300)
Distance from target: 23.45 m
Status: INSIDE geofence
🔴 ENTERED geofence - triggering mute
```

**View logs:**
```bash
flutter logs
# or
adb logcat | grep -i quietly
```

---

## ⚙️ Configuration

### **Change Target Location:**
```dart
// In map_service.dart or via database
await geoMute.updateTarget(
  latitude,   // Your target latitude
  longitude,  // Your target longitude
  radiusMeters  // Geofence radius in meters
);
```

### **Change Debounce Time:**
```dart
// In map_service.dart
static const int _debounceSeconds = 10;  // Change this value
```

### **Change Distance Filter:**
```dart
// In map_service.dart
locationSettings: const LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10,  // Update frequency in meters
  timeLimit: Duration(seconds: 30),
)
```

---

## 🚨 Common Issues & Solutions

### **Issue: App doesn't mute when entering location**

**Possible Causes:**
1. ❌ Background location permission not granted
   - **Solution**: Grant "Allow all the time" permission
2. ❌ DND access not granted
   - **Solution**: Grant DND permission in system settings
3. ❌ Battery optimization killing app
   - **Solution**: Disable battery optimization for Quietly
4. ❌ Location services disabled
   - **Solution**: Enable GPS in device settings

### **Issue: App doesn't unmute when leaving location**

**Possible Causes:**
1. ❌ App was force-closed
   - **Solution**: Foreground service should prevent this, but some manufacturers are aggressive
2. ❌ Debounce timer active
   - **Solution**: Wait 10 seconds after last trigger
3. ❌ Still within geofence radius
   - **Solution**: Move further than 40 meters from target

### **Issue: Rapid mute/unmute cycles**

**Possible Causes:**
1. ❌ GPS signal fluctuating
   - **Solution**: Debouncing should prevent this (10-second minimum)
2. ❌ Too close to geofence boundary
   - **Solution**: Increase geofence radius or move further from boundary

---

## 🔋 Battery Optimization

**Manufacturer-Specific Settings:**

Some manufacturers have aggressive battery optimization that can kill background services:

- **Samsung**: Settings → Apps → Quietly → Battery → Optimize battery usage → Disable
- **Xiaomi**: Settings → Battery & performance → Manage apps battery usage → Quietly → No restrictions
- **Huawei**: Settings → Battery → App launch → Quietly → Manage manually → Enable all
- **OnePlus**: Settings → Battery → Battery optimization → Quietly → Don't optimize

---

## 📝 Summary

Your app now:
- ✅ Automatically detects when you enter the specified location
- ✅ Enables Do Not Disturb mode (complete silence)
- ✅ Automatically detects when you leave the location
- ✅ Restores your previous audio settings exactly as they were
- ✅ Works in the background even when app is closed
- ✅ Persists state across app restarts
- ✅ Prevents rapid mute/unmute cycles
- ✅ Handles errors gracefully
- ✅ Provides detailed logging for troubleshooting

The system is production-ready and follows Android best practices for background location tracking and audio management.
