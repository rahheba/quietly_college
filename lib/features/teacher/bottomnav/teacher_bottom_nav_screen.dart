import 'package:flutter/material.dart';
import 'package:quietly/features/teacher/dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import 'package:quietly/features/teacher/attendance_mark/attendance.dart'; // adjust path as needed

class TeacherBottomNav extends StatefulWidget {
  const TeacherBottomNav({super.key});

  @override
  _TeacherBottomNavState createState() => _TeacherBottomNavState();
}

class _TeacherBottomNavState extends State<TeacherBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    TeacherDashboard(),
    TeacherProfile(),
    TeacherAttendanceModifier(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Attedence',
          ),
        ],
      ),
    );
  }
}
