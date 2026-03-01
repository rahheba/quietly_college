import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quietly/features/splash/splash_screen.dart';

import 'utils/methods/mute_fn.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When app is opened from notification tap, native calls this to (re-)activate background monitoring
  const backgroundChannel = MethodChannel('app.quietly.background');
  backgroundChannel.setMethodCallHandler((call) async {
    if (call.method == 'activateBackground') {
      await initGeoMute();
    }
    return null;
  });

  try {
    await Firebase.initializeApp();
    await initGeoMute();
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
