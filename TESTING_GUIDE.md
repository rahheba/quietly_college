# Testing Guide - Geofencing Auto-Mute

This guide will help you test the geofencing functionality to ensure it works correctly.

---

## 📋 Pre-Testing Checklist

### **1. Build the App**
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build debug APK for testing
flutter build apk --debug

# Or run directly on connected device
flutter run
```

### **2. Grant Required Permissions**

When you first launch the app, you'll need to grant:

#### **Location Permissions:**
1. Tap "Allow" when prompted for location access
2. **IMPORTANT**: Select **"Allow all the time"** (not "While using the app")
   - This is critical for background tracking
   - On Android 10+, you may need to grant this in two steps

#### **Do Not Disturb Permission:**
1. App will prompt you to grant DND access
2. Tap "Open Settings"
3. Find "Quietly" in the list
4. Toggle "Allow notification access" or "Do Not Disturb access" ON
5. Return to the app

### **3. Disable Battery Optimization**

To prevent Android from killing the background service:

1. Go to **Settings → Apps → Quietly**
2. Tap **Battery** or **Battery Usage**
3. Select **"Don't optimize"** or **"No restrictions"**

**Manufacturer-specific:**
- **Samsung**: Settings → Apps → Quietly → Battery → Optimize battery usage → Disable
- **Xiaomi**: Settings → Battery & performance → Manage apps battery usage → Quietly → No restrictions
- **Huawei**: Settings → Battery → App launch → Quietly → Manage manually → Enable all
- **OnePlus**: Settings → Battery → Battery optimization → Quietly → Don't optimize

---

## 🧪 Test Scenarios

### **Test 1: Basic Entry/Exit**

**Objective:** Verify phone mutes when entering geofence and unmutes when exiting

**Steps:**
1. **Check current target location:**
   - Default: Latitude `10.9756321`, Longitude `76.2172223`
   - Radius: `40 meters`
   - You can change this in `map_service.dart` if needed

2. **Start the app:**
   ```bash
   flutter run
   ```

3. **Monitor logs:**
   ```bash
   # In a separate terminal
   flutter logs | grep -i "geofence\|distance\|mute"
   ```

4. **Walk/drive to the target location:**
   - Use Google Maps to navigate to the coordinates
   - Or use GPS spoofing tools for testing (see below)

5. **Expected behavior when ENTERING:**
   - Log shows: `🔴 ENTERED geofence - triggering mute`
   - Phone goes silent (all volumes to 0)
   - DND mode enabled
   - Notification appears: "Quietly is Active"
   - Check manually: Try calling the phone - it should be silent

6. **Walk/drive AWAY from the location (>40m):**

7. **Expected behavior when EXITING:**
   - Log shows: `🟢 EXITED geofence - triggering unmute`
   - Phone returns to normal
   - Previous volume levels restored
   - Notification disappears
   - Check manually: Try calling the phone - it should ring normally

---

### **Test 2: Background Operation**

**Objective:** Verify geofencing works when app is in background

**Steps:**
1. Start the app
2. Press Home button (app goes to background)
3. Check notification tray - should see "Quietly is Active" notification
4. Walk to target location
5. Phone should still mute automatically
6. Walk away from location
7. Phone should unmute automatically

**Expected:**
- ✅ Geofencing works even when app is not visible
- ✅ Notification remains visible
- ✅ Mute/unmute happens automatically

---

### **Test 3: App Restart**

**Objective:** Verify state persists across app restarts

**Scenario A: Restart while OUTSIDE geofence**
1. Start app while outside geofence
2. Force close app
3. Restart app
4. Walk into geofence
5. Should mute normally

**Scenario B: Restart while INSIDE geofence**
1. Start app and walk into geofence (phone mutes)
2. Force close app
3. Restart app
4. Walk out of geofence
5. Should unmute normally (not mute again)

**Expected:**
- ✅ App remembers if you're inside or outside
- ✅ No duplicate mute/unmute triggers
- ✅ State restored from SharedPreferences

---

### **Test 4: Debouncing**

**Objective:** Verify rapid triggers are prevented

**Steps:**
1. Walk to the edge of the geofence boundary (~40m from target)
2. Walk back and forth across the boundary quickly
3. Monitor logs

**Expected:**
- ✅ First trigger happens normally
- ✅ Subsequent triggers within 10 seconds are ignored
- ✅ Log shows: `Debouncing: ignoring trigger`
- ✅ No rapid mute/unmute cycles

---

### **Test 5: Permission Denial**

**Objective:** Verify app handles missing permissions gracefully

**Steps:**
1. Revoke location permission: Settings → Apps → Quietly → Permissions → Location → Deny
2. Restart app
3. Check logs

**Expected:**
- ✅ Log shows: `Location permissions are denied`
- ✅ App doesn't crash
- ✅ Tracking doesn't start

**Steps:**
1. Revoke DND permission: Settings → Apps → Quietly → Notification access → Disable
2. Walk into geofence
3. Check behavior

**Expected:**
- ✅ App prompts to open settings
- ✅ Doesn't attempt to mute without permission
- ✅ No crash

---

### **Test 6: GPS Signal Loss**

**Objective:** Verify app recovers from GPS errors

**Steps:**
1. Start app with location enabled
2. Turn off location services: Settings → Location → OFF
3. Check logs
4. Turn location services back ON
5. Check logs

**Expected:**
- ✅ Log shows: `Location stream error`
- ✅ App attempts to restart tracking after 5 seconds
- ✅ Tracking resumes when GPS available

---

## 🛠️ GPS Spoofing for Testing (Optional)

If you can't physically go to the target location, use GPS spoofing:

### **Android GPS Spoofing:**

1. **Enable Developer Options:**
   - Settings → About Phone → Tap "Build Number" 7 times

2. **Install Fake GPS App:**
   - Download "Fake GPS Location" from Play Store
   - Or use "GPS Emulator" or similar

3. **Set Mock Location App:**
   - Settings → Developer Options → Select mock location app → Choose Fake GPS

4. **Spoof Location:**
   - Open Fake GPS app
   - Search for coordinates: `10.9756321, 76.2172223`
   - Tap "Start" or "Set Location"

5. **Test:**
   - Open Quietly app
   - Should detect you're "inside" the geofence
   - Phone should mute

6. **Change Location:**
   - In Fake GPS, move to a different location (>40m away)
   - Phone should unmute

---

## 📊 Monitoring & Debugging

### **View Logs:**

**Option 1: Flutter Logs**
```bash
flutter logs
```

**Option 2: Android Logcat**
```bash
adb logcat | grep -i quietly
```

**Option 3: Filtered Logs**
```bash
flutter logs | grep -E "geofence|distance|mute|ENTERED|EXITED"
```

### **Key Log Messages:**

**Successful Entry:**
```
Starting geofence tracking...
Target: (10.9756321, 76.2172223), Radius: 40.0 m
Current position: (10.9756500, 76.2172300)
Distance from target: 23.45 m
Status: INSIDE geofence
🔴 ENTERED geofence - triggering mute
```

**Successful Exit:**
```
Current position: (10.9760000, 76.2180000)
Distance from target: 85.32 m
Status: OUTSIDE geofence
🟢 EXITED geofence - triggering unmute
```

**Debouncing:**
```
Debouncing: ignoring trigger (5s since last)
```

**Permission Error:**
```
Cannot start tracking: insufficient permissions
Location permissions are denied
```

---

## ✅ Expected Results Summary

| Test Scenario | Expected Result |
|---------------|-----------------|
| Enter geofence | Phone mutes, DND enabled, notification shown |
| Exit geofence | Phone unmutes, volumes restored, notification hidden |
| Background operation | Works even when app not visible |
| App restart (outside) | Resumes tracking, mutes on entry |
| App restart (inside) | Remembers state, unmutes on exit |
| Rapid boundary crossing | Debouncing prevents rapid cycles |
| No location permission | Tracking doesn't start, no crash |
| No DND permission | Prompts for permission, no crash |
| GPS signal loss | Auto-recovers when signal returns |

---

## 🐛 Troubleshooting

### **Problem: Phone doesn't mute when entering location**

**Check:**
1. ✅ Location permission granted? (Settings → Apps → Quietly → Permissions)
2. ✅ Background location allowed? (Must be "Allow all the time")
3. ✅ DND permission granted? (Settings → Apps → Quietly → Notification access)
4. ✅ GPS enabled? (Settings → Location → ON)
5. ✅ Battery optimization disabled? (Settings → Apps → Quietly → Battery)
6. ✅ Actually within 40m of target? (Check logs for distance)

**Debug:**
```bash
flutter logs | grep -i "distance\|permission"
```

### **Problem: Phone doesn't unmute when leaving location**

**Check:**
1. ✅ Actually more than 40m away? (Check logs)
2. ✅ Debounce timer expired? (Wait 10+ seconds)
3. ✅ App still running? (Check notification)

**Debug:**
```bash
flutter logs | grep -i "exit\|distance"
```

### **Problem: App stops working in background**

**Check:**
1. ✅ Battery optimization disabled?
2. ✅ Foreground service running? (Check notification)
3. ✅ Manufacturer-specific battery settings?

**Debug:**
```bash
adb logcat | grep -i "QuietlyForegroundService"
```

### **Problem: Rapid mute/unmute cycles**

**Check:**
1. ✅ Debouncing should prevent this
2. ✅ Check if you're right at the boundary (~40m)
3. ✅ Move further from boundary

**Debug:**
```bash
flutter logs | grep -i "debounce\|distance"
```

---

## 📝 Test Report Template

After testing, document your results:

```
## Test Report - [Date]

### Device Information:
- Device: [e.g., Samsung Galaxy S21]
- Android Version: [e.g., Android 12]
- App Version: [e.g., 1.0.0]

### Test Results:

#### Test 1: Basic Entry/Exit
- [ ] PASS / [ ] FAIL
- Notes: 

#### Test 2: Background Operation
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 3: App Restart
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 4: Debouncing
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 5: Permission Denial
- [ ] PASS / [ ] FAIL
- Notes:

#### Test 6: GPS Signal Loss
- [ ] PASS / [ ] FAIL
- Notes:

### Issues Found:
1. 
2. 

### Overall Status:
- [ ] All tests passed
- [ ] Some tests failed (see issues)
- [ ] Ready for production
```

---

## 🚀 Production Deployment Checklist

Before releasing to users:

- [ ] All test scenarios pass
- [ ] Tested on multiple devices
- [ ] Tested on different Android versions
- [ ] Battery usage acceptable (check Settings → Battery)
- [ ] No memory leaks (monitor over 24 hours)
- [ ] Logs show no errors
- [ ] Permissions properly requested
- [ ] User documentation updated
- [ ] Target location configurable (not hardcoded)
- [ ] Build release APK: `flutter build apk --release`

---

**Happy Testing! 🎉**
