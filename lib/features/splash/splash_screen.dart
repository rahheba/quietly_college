import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/admin/admin_dashboard.dart';
import 'package:quietly/features/auth/view/login_screen.dart';
import 'package:quietly/features/bottom_nav/bottom_nav.dart';
import 'package:quietly/features/parent/parent_home.dart';
import 'package:quietly/features/teacher/bottomnav/teacher_bottom_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    // Wait for splash screen display duration
    await Future.delayed(Duration(seconds: 3));

    // Check if user is already logged in
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // User is logged in, check their role
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          String role = userDoc.get('role') ?? 'student';

          // Navigate based on role
          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
            );
          } else if (role == 'teacher') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TeacherBottomNav()),
            );
          } else if (role == 'parent') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ParentDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          }
        } else {
          // User document doesn't exist, logout and go to login
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        }
      } catch (e) {
        // Error fetching user data, go to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    } else {
      // User is not logged in, go to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFFF1616),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height:200,width:200,
              child: Image.asset('assets/quietlyicon.png', fit: BoxFit.cover)),
          ],
        ),
      ),
    );
  }
}
