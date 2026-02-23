import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeoMuteService {
  double? targetLat;
  double? targetLng;
  double targetRadiusMeters = 200.0;
  bool isInside = false;

  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastTriggerTime;
  static const int _debounceSeconds = 10; // Prevent rapid mute/unmute

  // State persistence keys
  static const String _keyIsInside = 'geomute_is_inside';
  static const String _keyTargetLat = 'geomute_target_lat';
  static const String _keyTargetLng = 'geomute_target_lng';
  static const String _keyTargetRadius = 'geomute_target_radius';

  /// Load target location from database/preferences
  Future<void> loadTargetFromDb() async {
    final prefs = await SharedPreferences.getInstance();

    // FORCE UPDATE: Use hardcoded values as source of truth
    // ignoring cached prefs to ensure code changes take effect
    targetLat = 10.9755134;
    targetLng = 76.2144442;

    targetRadiusMeters = prefs.getDouble(_keyTargetRadius) ?? 300.0;

    // FORCE RESET: Always start as 'outside' to ensure we trigger mute
    // if the user starts the app while already inside the zone.
    isInside = false;

    // Save updated values to preferences
    await _saveTargetToPrefs();
  }

  /// Save target location to preferences
  Future<void> _saveTargetToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTargetLat, targetLat ?? 0);
    await prefs.setDouble(_keyTargetLng, targetLng ?? 0);
    await prefs.setDouble(_keyTargetRadius, targetRadiusMeters);
  }

  /// Save current inside/outside state
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsInside, isInside);
  }

  /// Check and request location permissions
  Future<bool> _checkPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    // Request background location permission (Android 10+)
    if (permission == LocationPermission.whileInUse) {
      print(
        'Warning: Only foreground location permission granted. Background tracking may not work.',
      );
      // On Android, you may need to request background permission separately
      // This requires additional setup in AndroidManifest.xml
    }

    return true;
  }

  /// Start tracking location and trigger callbacks on geofence entry/exit
  Future<void> startTracking({
    required Future<void> Function() onEnter,
    required Future<void> Function() onExit,
  }) async {
    // Check permissions first
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      print('Cannot start tracking: insufficient permissions');
      return;
    }

    // Load target location
    await loadTargetFromDb();

    if (targetLat == null || targetLng == null) {
      print('Cannot start tracking: target location not set');
      return;
    }

    // Cancel existing subscription if any
    await stopTracking();

    print('Starting geofence tracking...');
    print('Target: ($targetLat, $targetLng), Radius: $targetRadiusMeters m');

    // Start listening to position updates
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
            timeLimit: Duration(seconds: 30), // Timeout for location updates
          ),
        ).listen(
          (Position pos) async {
            await _handlePositionUpdate(pos, onEnter, onExit);
          },
          onError: (error) {
            print('Location stream error: $error');
            // Attempt to restart tracking after error
            Future.delayed(const Duration(seconds: 5), () {
              startTracking(onEnter: onEnter, onExit: onExit);
            });
          },
          cancelOnError: false,
        );
  }

  /// Handle position updates and trigger geofence events
  Future<void> _handlePositionUpdate(
    Position pos,
    Future<void> Function() onEnter,
    Future<void> Function() onExit,
  ) async {
    if (targetLat == null || targetLng == null) return;

    final distance = _distanceMeters(
      pos.latitude,
      pos.longitude,
      targetLat!,
      targetLng!,
    );

    final nowInside = distance <= targetRadiusMeters;

    print('--------------------------------------------------');
    print('📍 CURRENT LOCATION: ${pos.latitude}, ${pos.longitude}');
    print('🎯 TARGET LOCATION : $targetLat, $targetLng');
    print('📏 DISTANCE       : ${distance.toStringAsFixed(2)} meters');
    print('⭕ RADIUS         : $targetRadiusMeters meters');
    print('🤔 STATUS         : ${nowInside ? "INSIDE ✅" : "OUTSIDE ❌"}');
    print('--------------------------------------------------');

    // Debounce: prevent rapid triggers
    if (_lastTriggerTime != null) {
      final timeSinceLastTrigger = DateTime.now().difference(_lastTriggerTime!);
      if (timeSinceLastTrigger.inSeconds < _debounceSeconds) {
        print(
          'Debouncing: ignoring trigger (${timeSinceLastTrigger.inSeconds}s since last)',
        );
        return;
      }
    }

    // Detect entry into geofence
    if (nowInside && !isInside) {
      print('🔴 ENTERED geofence - triggering mute');
      isInside = true;
      _lastTriggerTime = DateTime.now();
      await _saveState();

      try {
        await onEnter();
      } catch (e) {
        print('Error in onEnter callback: $e');
      }
    }
    // Detect exit from geofence
    else if (!nowInside && isInside) {
      print('🟢 EXITED geofence - triggering unmute');
      isInside = false;
      _lastTriggerTime = DateTime.now();
      await _saveState();

      try {
        await onExit();
      } catch (e) {
        print('Error in onExit callback: $e');
      }
    }
  }

  /// Stop tracking and clean up resources
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    print('Stopped geofence tracking');
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180.0;

  /// Update target location (e.g., from database or user input)
  Future<void> updateTarget(double lat, double lng, double radiusMeters) async {
    targetLat = lat;
    targetLng = lng;
    targetRadiusMeters = radiusMeters;
    await _saveTargetToPrefs();
    print('Updated target location: ($lat, $lng), radius: $radiusMeters m');
  }

  /// Dispose and clean up
  void dispose() {
    _positionSubscription?.cancel();
  }
}
