import 'package:flutter/services.dart';

class GeoMuteService {
  static const MethodChannel _channel = MethodChannel('geo_mute_channel');
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLog') {
        print('[Native GeoMute] ${call.arguments}');
      }
    });
  }

  static Future<void> startMonitoring({
    required double latitude,
    required double longitude,
  }) async {
    initialize();
    try {
      await _channel.invokeMethod('startMonitoring', {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      print("Failed to start monitoring: ${e.toString()}");
    }
  }

  static Future<void> stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (e) {
      print("Failed to stop monitoring: ${e.toString()}");
    }
  }
}
