import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String _teacherName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _teacherName = doc.data()?['name']?.toString() ?? 'Teacher';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_teacherName!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildTeacherCard(
              icon: Icons.people,
              title: 'Students in Class Mode',
              count: '0',
              color: Colors.green,
            ),
            SizedBox(height: 16),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Classes')
                  .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .snapshots(),
              builder: (context, classesSnapshot) {
                if (!classesSnapshot.hasData || classesSnapshot.data!.docs.isEmpty) {
                  return _buildTeacherCard(
                    icon: Icons.phone_disabled,
                    title: 'Total Students',
                    count: '0',
                    color: Colors.blue,
                  );
                }
                final firstClassId = classesSnapshot.data!.docs.first.id;
                return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Classes')
                      .doc(firstClassId)
                      .collection('Students')
                      .snapshots(),
                  builder: (context, studentsSnapshot) {
                    int total = studentsSnapshot.hasData ? studentsSnapshot.data!.docs.length : 0;
                    return _buildTeacherCard(
                      icon: Icons.phone_disabled,
                      title: 'Total Students',
                      count: total.toString(),
                      color: Colors.blue,
                    );
                  },
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              'Students in Your Classes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Classes')
                    .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                    .snapshots(),
                builder: (context, classesSnapshot) {
                  if (!classesSnapshot.hasData || classesSnapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No classes yet. Create a class to add students.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  final classIds = classesSnapshot.data!.docs.map((d) => d.id).toList();
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('Classes')
                        .doc(classIds.first)
                        .collection('Students')
                        .snapshots(),
                    builder: (context, studentsSnapshot) {
                      if (!studentsSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final students = studentsSnapshot.data!.docs;
                      if (students.isEmpty) {
                        return Center(
                          child: Text(
                            'No students in this class yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index].data();
                          final name = s['name']?.toString() ?? 'Unknown';
                          final roll = s['rollNo']?.toString() ?? s['email']?.toString() ?? '';
                          return _buildStudentTile(name, roll.isNotEmpty ? 'Roll: $roll' : 'Student', false);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(String name, String rollNo, bool isInClassMode) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isInClassMode ? Colors.green : Colors.grey,
          child: Icon(
            isInClassMode ? Icons.phone_disabled : Icons.phone_android,
            color: Colors.white,
          ),
        ),
        title: Text(name),
        subtitle: Text(rollNo),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isInClassMode ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isInClassMode ? 'In Class' : 'Not Active',
            style: TextStyle(
              color: isInClassMode
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
