import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
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
              'Welcome, Teacher!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildTeacherCard(
              icon: Icons.people,
              title: 'Students in Class Mode',
              count: '15',
              color: Colors.green,
            ),
            SizedBox(height: 16),
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('Users').where('role',isEqualTo: 'student').snapshots(),
              builder: (context, asyncSnapshot) {
                return _buildTeacherCard(
                  icon: Icons.phone_disabled,
                  title: 'Total Students',
                  count: asyncSnapshot.hasData?asyncSnapshot.data!.docs.length.toString():'0',
                  color: Colors.blue,
                );
              }
            ),
            SizedBox(height: 24),
            Text(
              'Students Currently in Class Mode:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildStudentTile('Alex Johnson', 'Roll: 15', true),
                  _buildStudentTile('Sarah Smith', 'Roll: 08', true),
                  _buildStudentTile('Mike Brown', 'Roll: 22', true),
                  _buildStudentTile('Emma Davis', 'Roll: 11', false),
                  _buildStudentTile('James Wilson', 'Roll: 19', true),
                ],
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
