# Geofencing Flow Diagram

## 🔄 Complete Application Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP STARTUP                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  main.dart       │
                    │  - Init Firebase │
                    │  - Init GeoMute  │
                    └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GEOFENCING SERVICE INIT                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Check Permissions│
                    └──────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
            ┌──────────────┐    ┌──────────────┐
            │  GRANTED     │    │   DENIED     │
            └──────────────┘    └──────────────┘
                    │                   │
                    │                   ▼
                    │           ┌──────────────┐
                    │           │ Request Perm │
                    │           └──────────────┘
                    │                   │
                    └───────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Load Target from │
                    │ SharedPreferences│
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Start Location   │
                    │ Stream (10m)     │
                    └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONTINUOUS MONITORING                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │ Every 10 meters   │
                    └─────────┬─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Get GPS Position │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Calculate        │
                    │ Distance (m)     │
                    └──────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
          ┌──────────────────┐  ┌──────────────────┐
          │ Distance ≤ 40m   │  │ Distance > 40m   │
          │ (INSIDE)         │  │ (OUTSIDE)        │
          └──────────────────┘  └──────────────────┘
                    │                   │
                    │                   │
          ┌─────────┴─────────┐         │
          │ Was OUTSIDE?      │         │
          └─────────┬─────────┘         │
                    │ YES               │
                    ▼                   │
┌─────────────────────────────────────────────────────────────────┐
│                      GEOFENCE ENTRY                             │
└─────────────────────────────────────────────────────────────────┘
                    │                   │
                    ▼                   │
          ┌──────────────────┐          │
          │ Check Debounce   │          │
          │ (>10s since last)│          │
          └──────────────────┘          │
                    │                   │
                    ▼                   │
          ┌──────────────────┐          │
          │ Save State       │          │
          │ (isInside=true)  │          │
          └──────────────────┘          │
                    │                   │
                    ▼                   │
          ┌──────────────────┐          │
          │ onEnter()        │          │
          │ Callback         │          │
          └──────────────────┘          │
                    │                   │
                    ▼                   │
┌─────────────────────────────────────────────────────────────────┐
│                      MUTE PHONE                                 │
└─────────────────────────────────────────────────────────────────┘
                    │                   │
                    ▼                   │
          ┌──────────────────┐          │
          │ Check DND Access │          │
          └──────────────────┘          │
                    │                   │
          ┌─────────┴─────────┐         │
          │                   │         │
          ▼                   ▼         │
    ┌──────────┐      ┌──────────┐     │
    │ GRANTED  │      │ DENIED   │     │
    └──────────┘      └──────────┘     │
          │                   │         │
          │                   ▼         │
          │           ┌──────────────┐  │
          │           │ Open Settings│  │
          │           └──────────────┘  │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Start Foreground │                    │
│ Service          │                    │
└──────────────────┘                    │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Save Current     │                    │
│ Audio State      │                    │
│ - Ringer mode    │                    │
│ - Ring volume    │                    │
│ - Notif volume   │                    │
│ - Music volume   │                    │
└──────────────────┘                    │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Set DND Mode     │                    │
│ INTERRUPTION_    │                    │
│ FILTER_NONE      │                    │
└──────────────────┘                    │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Set Ringer to    │                    │
│ SILENT           │                    │
└──────────────────┘                    │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Mute All Streams │                    │
│ - Ring: 0        │                    │
│ - Notification: 0│                    │
│ - System: 0      │                    │
│ - Music: 0       │                    │
└──────────────────┘                    │
          │                             │
          ▼                             │
┌──────────────────┐                    │
│ Show Notification│                    │
│ "Quietly Active" │                    │
└──────────────────┘                    │
          │                             │
          └─────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Continue         │
                    │ Monitoring       │
                    └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GEOFENCE EXIT                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │ Was INSIDE?       │
                    └─────────┬─────────┘
                              │ YES
                              ▼
                    ┌──────────────────┐
                    │ Check Debounce   │
                    │ (>10s since last)│
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Save State       │
                    │ (isInside=false) │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ onExit()         │
                    │ Callback         │
                    └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      UNMUTE PHONE                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Restore DND      │
                    │ Filter           │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Restore Ringer   │
                    │ Mode             │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Restore Volumes  │
                    │ - Ring           │
                    │ - Notification   │
                    │ - Music          │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Stop Foreground  │
                    │ Service          │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Hide Notification│
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Continue         │
                    │ Monitoring       │
                    └──────────────────┘
```

---

## 🔧 Error Handling Flow

```
┌──────────────────┐
│ Location Stream  │
│ Error            │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│ Log Error        │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│ Wait 5 seconds   │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│ Restart Tracking │
└──────────────────┘
```

---

## 📱 State Persistence

```
┌─────────────────────────────────────────┐
│         SharedPreferences               │
├─────────────────────────────────────────┤
│ geomute_is_inside: true/false           │
│ geomute_target_lat: 10.9756321          │
│ geomute_target_lng: 76.2172223          │
│ geomute_target_radius: 40.0             │
│                                         │
│ prev_ringer_mode: 2 (NORMAL)            │
│ prev_ring_volume: 7                     │
│ prev_notification_volume: 5             │
│ prev_music_volume: 10                   │
│ prev_dnd_filter: 1 (ALL)                │
└─────────────────────────────────────────┘
         ▲                    │
         │                    │
    Save State           Load State
         │                    │
         │                    ▼
┌─────────────────────────────────────────┐
│         App Restart                     │
│  - Remembers if inside geofence         │
│  - Remembers target location            │
│  - Remembers previous audio settings    │
└─────────────────────────────────────────┘
```

---

## ⏱️ Debouncing Logic

```
Time: 0s        10s       20s       30s
      │         │         │         │
      ▼         ▼         ▼         ▼
    ENTER     ENTER     ENTER     EXIT
      │         │         │         │
      ▼         ▼         ▼         ▼
    MUTE      IGNORE    IGNORE    UNMUTE
    (OK)    (debounce) (debounce)  (OK)
```

**Prevents:**
- GPS jitter causing rapid mute/unmute
- Battery drain from excessive triggers
- Annoying user experience

---

## 🎯 Distance Calculation (Haversine Formula)

```
User Position: (lat1, lon1)
Target Position: (lat2, lon2)

Step 1: Convert to radians
  dLat = (lat2 - lat1) * π/180
  dLon = (lon2 - lon1) * π/180

Step 2: Haversine formula
  a = sin²(dLat/2) + cos(lat1) * cos(lat2) * sin²(dLon/2)
  c = 2 * atan2(√a, √(1-a))
  
Step 3: Distance in meters
  distance = 6371000 * c

Step 4: Check geofence
  if (distance ≤ 40m) → INSIDE
  if (distance > 40m) → OUTSIDE
```

---

## 📊 Accuracy Considerations

| GPS Accuracy | Indoor | Outdoor | Urban | Rural |
|--------------|--------|---------|-------|-------|
| Best         | 20-50m | 5-10m   | 10-20m| 3-5m  |
| Typical      | 50-100m| 10-20m  | 20-40m| 5-10m |
| Worst        | >100m  | 20-50m  | 40-80m| 10-20m|

**Recommendation:** Use 40m+ radius for reliable geofencing

---

**This flow ensures reliable, battery-efficient geofencing with proper state management and error recovery!**
