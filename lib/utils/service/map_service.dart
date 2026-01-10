import 'dart:math';
import 'package:geolocator/geolocator.dart';

class GeoMuteService {
  double? targetLat;
  double? targetLng;
  double targetRadiusMeters = 200.0; // from DB
  bool isInside = false;

  Future<void> loadTargetFromDb() async {
    targetLat = 10.9756321;
    targetLng = 76.2172223;
    targetRadiusMeters = 40.0;
  }

  Future<void> startTracking({
    required Future<void> Function() onEnter,
    required Future<void> Function() onExit,
  }) async {
    await Geolocator.requestPermission();
    await loadTargetFromDb();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25, // meters
      ),
    ).listen((pos) async {
      if (targetLat == null || targetLng == null) return;

      final d = _distanceMeters(pos.latitude, pos.longitude, targetLat!, targetLng!);
      final nowInside = d <= targetRadiusMeters;

      if (nowInside && !isInside) {
        isInside = true;
        await onEnter();
      } else if (!nowInside && isInside) {
        isInside = false;
        await onExit();
      }
    });
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat/2) * sin(dLat/2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180.0;
}
