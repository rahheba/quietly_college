import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/splash/splash_screen.dart';
import 'package:quietly/utils/service/geo_mute_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // Start tracking the target location automatically on app launch
    await GeoMuteService.startMonitoring(
      latitude: 10.9575776,
      longitude: 76.3092229,
    );
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quietly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}
