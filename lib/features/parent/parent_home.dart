import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/parent/profile_screen.dart';
import 'package:quietly/features/parent/show_attendence.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int selectedChildIndex = 0;
  List<Map<String, dynamic>> children = [];
  List<DocumentSnapshot> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }
      final parentDoc = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: user.email)
          .where('role', isEqualTo: 'parent')
          .limit(1)
          .get();
      if (parentDoc.docs.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      final parentId = parentDoc.docs.first.id;
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .get();
      classes = classesSnapshot.docs;
      children.clear();
      for (var classDoc in classes) {
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('Classes')
            .doc(classDoc.id)
            .collection('Students')
            .where('parentid', isEqualTo: parentId)
            .get();
        for (var studentDoc in studentsSnapshot.docs) {
          final data = studentDoc.data();
          final name = data['name']?.toString() ?? 'Child';
          final initials = name.isNotEmpty
              ? name
                    .split(' ')
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase()
              : '?';

          // Fetch today's attendance
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

          final attendanceSnapshot = await FirebaseFirestore.instance
              .collection('Classes')
              .doc(classDoc.id)
              .collection('Students')
              .doc(studentDoc.id)
              .collection('attendance')
              .where('date', isGreaterThanOrEqualTo: startOfDay)
              .where('date', isLessThanOrEqualTo: endOfDay)
              .get();

          int attended = 0;
          String todayStatus = 'Absent';
          if (attendanceSnapshot.docs.isNotEmpty) {
            attended = attendanceSnapshot.docs
                .where(
                  (doc) =>
                      doc.data()['status'] == 'present' ||
                      doc.data()['status'] == 'late',
                )
                .length;
            todayStatus = attended > 0 ? 'Present' : 'Absent';
          }

          children.add({
            'id': studentDoc.id,
            'classId': classDoc.id,
            'name': name,
            'grade': data['classname']?.toString() ?? 'N/A',
            'avatar': initials.length >= 2
                ? initials
                : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
            'todayAttendance': todayStatus,
            'phoneStatus': 'Active',
            'totalClasses': 6,
            'attendedToday': attended,
            'currentClass': _getCurrentClassStatus(),
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  Stream<QuerySnapshot> _getActivityStream(String classId, String studentId) {
    if (classId.isEmpty || studentId.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('Classes')
        .doc(classId)
        .collection('Students')
        .doc(studentId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots();
  }

  String _formatActivityTime(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Stream<QuerySnapshot> _getSchedulesStream(String classId) {
    if (classId.isEmpty) return const Stream.empty();
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return FirebaseFirestore.instance
        .collection('Classes')
        .doc(classId)
        .collection('Schedules')
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .snapshots();
  }

  String _getCurrentClassStatus() {
    final now = DateTime.now();
    final double hour = now.hour + now.minute / 60.0;

    // Schedule:
    // P1: 09:30 - 10:30 (9.5 - 10.5)
    // P2: 10:30 - 11:30 (10.5 - 11.5)
    // Break: 11:30 - 11:45
    // P3: 11:45 - 12:45 (11.75 - 12.75)
    // Lunch: 12:45 - 13:15
    // P4: 13:15 - 14:15 (13.25 - 14.25)
    // P5: 14:15 - 15:15 (14.25 - 15.25)

    if (hour >= 9.5 && hour < 10.5) return 'Period 1';
    if (hour >= 10.5 && hour < 11.5) return 'Period 2';
    if (hour >= 11.5 && hour < 11.75) return 'Short Break';
    if (hour >= 11.75 && hour < 12.75) return 'Period 3';
    if (hour >= 12.75 && hour < 13.25) return 'Lunch Break';
    if (hour >= 13.25 && hour < 14.25) return 'Period 4';
    if (hour >= 14.25 && hour < 15.25) return 'Period 5';
    if (hour >= 15.25) return 'School Over';
    if (hour < 9.5) return 'Not Started';

    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF3C7),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 1),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (children.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF3C7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Quietly'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No children linked to your account yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact your school to link your children.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final selectedChild =
        children[selectedChildIndex.clamp(0, children.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_android, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quietly',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Parent Dashboard',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParentProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Child',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final isSelected = selectedChildIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChildIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFB45309)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFFEF3C7),
                              child: Text(
                                child['avatar'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFB45309),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  child['name'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  child['grade'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFFEF3C7)
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    title: 'Today\'s Attendance',
                    value:
                        '${selectedChild['attendedToday']}/${selectedChild['totalClasses']}',
                    badge: selectedChild['todayAttendance'],
                    badgeColor: Colors.green.shade50,
                    badgeTextColor: Colors.green.shade700,
                    gradientColors: [
                      Colors.green.shade400,
                      Colors.green.shade700,
                    ],
                  ),
                  _buildStatCard(
                    icon: Icons.phone_android_outlined,
                    iconColor: const Color(0xFFD97706),
                    title: 'Phone Status',
                    value: 'Active',
                    badge: selectedChild['phoneStatus'],
                    badgeColor: const Color(0xFFFEF3C7),
                    badgeTextColor: const Color(0xFFB45309),
                    gradientColors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFB45309),
                    ],
                  ),
                  _buildStatCard(
                    icon: Icons.calendar_today_outlined,
                    iconColor: Colors.indigo,
                    title: 'Current Class',
                    value: selectedChild['currentClass'],
                    gradientColors: [
                      Colors.indigo.shade400,
                      Colors.indigo.shade700,
                    ],
                  ),
                  _buildStatCard(
                    icon: Icons.access_time_outlined,
                    iconColor: Colors.orange,
                    title: 'Remaining',
                    value:
                        '${selectedChild['totalClasses'] - selectedChild['attendedToday']}',
                    gradientColors: [
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getActivityStream(
                        selectedChild['classId'],
                        selectedChild['id'],
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'No recent activity',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final subject =
                                data['subjectTitle']?.toString() ?? 'Class';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Entered $subject class',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatActivityTime(
                                            data['date'] as Timestamp?,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today Classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getSchedulesStream(selectedChild['classId']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No classes scheduled for today',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        // Sort in memory like in student home
                        docs.sort((a, b) {
                          final aId =
                              (a.data() as Map<String, dynamic>)['periodId']
                                  ?.toString() ??
                              '';
                          final bId =
                              (b.data() as Map<String, dynamic>)['periodId']
                                  ?.toString() ??
                              '';
                          return aId.compareTo(bId);
                        });

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(
                                12,
                              ), // Reduced padding
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFEF3C7),
                                    Color(0xFFFED7AA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFEBD38),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Period ${data['periodId'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['subjectTitle'] ?? 'No Title',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['time'] ?? 'N/A',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        // _buildQuickAction(
                        //   icon: Icons.calendar_today,
                        //   label: 'View Full Schedule',
                        //   onTap: () {},
                        // ),
                        _buildQuickAction(
                          icon: Icons.check_circle_outline,
                          label: 'Attendance Report',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParentAttendanceScreen(
                                  initialChildId: selectedChild['id'],
                                ),
                              ),
                            );
                          },
                        ),
                        // _buildQuickAction(
                        //   icon: Icons.phone_android,
                        //   label: 'Phone Settings',
                        //   onTap: () {},
                        // ),
                        // _buildQuickAction(
                        //   icon: Icons.notifications_outlined,
                        //   label: 'Notifications',
                        //   onTap: () {},
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFFEF3C7).withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: gradientColors[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: gradientColors[0], size: 18),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFEBD38), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB45309), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
