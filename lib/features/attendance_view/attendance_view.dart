import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentAttendanceViewer extends StatefulWidget {
  const StudentAttendanceViewer({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceViewer> createState() =>
      _StudentAttendanceViewerState();
}

class _StudentAttendanceViewerState extends State<StudentAttendanceViewer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedMonth = DateTime.now().month.toString();
  String selectedPeriod = 'all';
  bool isLoading = true;

  Map<String, String> studentInfo = {
    'id': '',
    'name': 'Loading...',
    'class': '',
    'section': '',
    'rollNo': '',
    'classId': '',
  };

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() => isLoading = false);
        return;
      }

      final userData = userDoc.data()!;

      // We need to find the student's classId from the Classes collection
      final classesSnapshot = await _firestore.collection('Classes').get();
      String studentClassId = '';

      for (var classDoc in classesSnapshot.docs) {
        final studentSnapshot = await _firestore
            .collection('Classes')
            .doc(classDoc.id)
            .collection('Students')
            .doc(user.uid)
            .get();

        if (studentSnapshot.exists) {
          studentClassId = classDoc.id;
          break;
        }
      }

      if (mounted) {
        setState(() {
          studentInfo = {
            'id': user.uid,
            'name': userData['name']?.toString() ?? 'Student',
            'class': userData['classname']?.toString() ?? '',
            'section': userData['section']?.toString() ?? 'A',
            'rollNo':
                userData['rollNo']?.toString() ??
                userData['rollno']?.toString() ??
                '',
            'classId': studentClassId,
          };
        });

        await _loadAttendanceData();
      }
    } catch (e) {
      print('Error loading student info: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAttendanceData() async {
    if (studentInfo['classId']!.isEmpty || studentInfo['id']!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      setState(() => isLoading = true);

      final currentYear = DateTime.now().year;
      final selectedMonthIndex = months.indexOf(selectedMonth) + 1;

      final startDate = DateTime(currentYear, selectedMonthIndex, 1);
      final endDate = DateTime(
        currentYear,
        selectedMonthIndex + 1,
        0,
        23,
        59,
        59,
      );

      final attendanceSnapshot = await _firestore
          .collection('Classes')
          .doc(studentInfo['classId'])
          .collection('Students')
          .doc(studentInfo['id'])
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();

      attendanceRecords.clear();
      attendanceStats = {'total': 0, 'present': 0, 'absent': 0, 'late': 0};

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'absent';

        attendanceRecords.add({
          'id': doc.id,
          'date': data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          'period': data['period']?.toString() ?? '',
          'periodTime': data['periodTime']?.toString() ?? '',
          'status': status,
          'markedBy': data['markedBy']?.toString() ?? 'system',
          'markedAt': data['markedAt'] is Timestamp
              ? (data['markedAt'] as Timestamp).toDate()
              : null,
        });

        attendanceStats['total'] = (attendanceStats['total'] ?? 0) + 1;
        attendanceStats[status] = (attendanceStats[status] ?? 0) + 1;
      }
    } catch (e) {
      print('Error loading attendance: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<Map<String, String>> periods = [
    {'id': '1', 'name': 'Period 1'},
    {'id': '2', 'name': 'Period 2'},
    {'id': '3', 'name': 'Period 3'},
    {'id': '4', 'name': 'Period 4'},
    {'id': '5', 'name': 'Period 5'},
  ];

  List<Map<String, dynamic>> attendanceRecords = [];
  Map<String, int> attendanceStats = {
    'total': 0,
    'present': 0,
    'absent': 0,
    'late': 0,
  };

  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade100;
      case 'absent':
        return Colors.red.shade100;
      case 'late':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade800;
      case 'absent':
        return Colors.red.shade800;
      case 'late':
        return Colors.yellow.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  List<Map<String, dynamic>> getFilteredRecords() {
    return attendanceRecords.where((record) {
      final recordDate = record['date'] as DateTime;
      final matchesMonth = recordDate.month.toString() == selectedMonth;
      final matchesPeriod =
          selectedPeriod == 'all' || record['period'] == selectedPeriod;
      return matchesMonth && matchesPeriod;
    }).toList()..sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
  }

  Map<String, int> getAttendanceStats() {
    final filtered = getFilteredRecords();
    return {
      'total': filtered.length,
      'present': filtered.where((r) => r['status'] == 'present').length,
      'absent': filtered.where((r) => r['status'] == 'absent').length,
      'late': filtered.where((r) => r['status'] == 'late').length,
    };
  }

  double getAttendancePercentage() {
    final stats = getAttendanceStats();
    if (stats['total'] == 0) return 0.0;
    return ((stats['present']! + stats['late']!) / stats['total']!) * 100;
  }

  String formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = getFilteredRecords();
    final stats = getAttendanceStats();
    final percentage = getAttendancePercentage();

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade600,
        title: const Text('My Attendance'),
        elevation: 0,
      ),
      body: isLoading && studentInfo['id']!.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (studentInfo['id']!.isNotEmpty) {
                  await _loadAttendanceData();
                } else {
                  await _loadStudentInfo();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Student Info Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade600,
                            Colors.indigo.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              studentInfo['name']![0],
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            studentInfo['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${studentInfo['id']} • Roll No: ${studentInfo['rollNo']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${studentInfo['class']} - Section ${studentInfo['section']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Attendance Percentage Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: percentage >= 75
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : percentage >= 60
                                ? [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ]
                                : [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Overall Attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              percentage >= 75
                                  ? 'Excellent Attendance! 🎉'
                                  : percentage >= 60
                                  ? 'Good, but can improve 📈'
                                  : 'Needs Improvement ⚠️',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${stats['total']}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total Classes',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${stats['present']}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Present',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${stats['absent']}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Absent',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              color: Colors.yellow.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.yellow.shade700,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${stats['late']}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Late',
                                      style: TextStyle(
                                        color: Colors.yellow.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filter Attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          value: selectedMonth,
                                          decoration: InputDecoration(
                                            labelText: 'Month',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: List.generate(12, (index) {
                                            return DropdownMenuItem(
                                              value: (index + 1).toString(),
                                              child: Text(months[index]),
                                            );
                                          }),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedMonth = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          value: selectedPeriod,
                                          decoration: InputDecoration(
                                            labelText: 'Period',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: 'all',
                                              child: Flexible(
                                                child: Text(
                                                  'All Periods',
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            ...periods.map((period) {
                                              return DropdownMenuItem(
                                                value: period['id'],
                                                child: Text(period['name']!),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPeriod = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Attendance Records
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 12),
                            child: Text(
                              'Attendance History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.all(48.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (filteredRecords.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No attendance records found',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            ...filteredRecords.map((record) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Period ' +
                                                      (record['period']
                                                              ?.toString() ??
                                                          ''),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formatDate(
                                                    record['date'] as DateTime,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(
                                                record['status'] as String,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: getStatusTextColor(
                                                  record['status'] as String,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  getStatusIcon(
                                                    record['status'] as String,
                                                  ),
                                                  size: 16,
                                                  color: getStatusTextColor(
                                                    record['status'] as String,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (record['status']
                                                              as String)[0]
                                                          .toUpperCase() +
                                                      (record['status']
                                                              as String)
                                                          .substring(1),
                                                  style: TextStyle(
                                                    color: getStatusTextColor(
                                                      record['status']
                                                          as String,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${record['period']} • ${record['periodTime'] != null && record['periodTime'].toString().isNotEmpty ? record['periodTime'] : 'No entry time'}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  record['markedBy'] == 'auto'
                                                  ? Colors.blue.shade50
                                                  : Colors.purple.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  record['markedBy'] == 'auto'
                                                      ? Icons.smartphone
                                                      : Icons.person,
                                                  size: 12,
                                                  color:
                                                      record['markedBy'] ==
                                                          'auto'
                                                      ? Colors.blue.shade700
                                                      : Colors.purple.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  record['markedBy'] == 'auto'
                                                      ? 'Auto-tracked'
                                                      : 'By Teacher',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        record['markedBy'] ==
                                                            'auto'
                                                        ? Colors.blue.shade700
                                                        : Colors
                                                              .purple
                                                              .shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }
}
