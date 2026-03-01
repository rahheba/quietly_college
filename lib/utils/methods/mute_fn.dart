import 'package:quietly/utils/service/dns_service.dart';

import '../service/map_service.dart';

final geoMute = GeoMuteService();
final dnd = DndService();

Future<void> initGeoMute() async {
  // Start foreground service immediately so tracking works in background (300m radius)
  await dnd.startMonitoring();
  await geoMute.startTracking(
    onEnter: () async {
      if (!await dnd.hasAccess()) {
        // Prompt once: explain why and open settings
        await dnd.openSettings();
        return;
      }
      await dnd.setSilent(); // Android: full silence
      // iOS: Optional — mute app audio or show a prompt
    },
    onExit: () async {
      await dnd.restore();   // Android: back to previous state
      // iOS: Optional — unmute app audio
    },
  );
}

