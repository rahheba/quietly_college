import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> childrenData = [];
  Map<String, List<Map<String, dynamic>>> attendanceData = {};
  Map<String, Map<String, dynamic>> attendanceStats = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String selectedChildId = '';
  String selectedMonth = '';
  String filterPeriod = 'all';
  String filterStatus = 'all';

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

  @override
  void initState() {
    super.initState();
    selectedMonth = months[selectedDate.month - 1];
    _loadChildrenData();
  }

  Future<void> _loadChildrenData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() => isLoading = true);

      // Get parent data
      final parentDoc = await _firestore
          .collection('Users')
          .where('email', isEqualTo: user.email)
          .where('role', isEqualTo: 'parent')
          .limit(1)
          .get();

      if (parentDoc.docs.isEmpty) return;

      final parentId = parentDoc.docs.first.id;

      // Load all classes first
      final classesSnapshot = await _firestore.collection('Classes').get();
      final classes = classesSnapshot.docs;

      childrenData.clear();

      // Find children for this parent across all classes
      for (var classDoc in classes) {
        final studentsSnapshot = await _firestore
            .collection('Classes')
            .doc(classDoc.id)
            .collection('Students')
            .where('parentid', isEqualTo: parentId)
            .get();

        for (var studentDoc in studentsSnapshot.docs) {
          final studentData = studentDoc.data() as Map<String, dynamic>? ?? {};
          studentData['id'] = studentDoc.id;
          studentData['classId'] = classDoc.id;
          studentData['classname'] =
              studentData['classname']?.toString() ?? 'Unknown Class';

          childrenData.add(studentData);
        }
      }

      if (childrenData.isNotEmpty) {
        selectedChildId = childrenData.first['id']?.toString() ?? '';
        await _loadAttendanceData();
      }
    } catch (e) {
      print('Error loading children: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAttendanceData() async {
    if (selectedChildId.isEmpty || childrenData.isEmpty) return;

    try {
      setState(() => isLoading = true);

      final selectedChild = childrenData.firstWhere(
        (child) => child['id']?.toString() == selectedChildId,
        orElse: () => childrenData.first,
      );

      final classId = selectedChild['classId']?.toString();
      if (classId == null) return;

      final currentYear = selectedDate.year;
      final selectedMonthIndex = months.indexOf(selectedMonth) + 1;

      // Calculate start and end dates for the selected month
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
          .doc(classId)
          .collection('Students')
          .doc(selectedChildId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();

      attendanceData[selectedChildId] = [];
      attendanceStats[selectedChildId] = {
        'total': 0,
        'present': 0,
        'absent': 0,
        'late': 0,
        'percentage': 0.0,
      };

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status']?.toString() ?? 'absent';

        attendanceData[selectedChildId]!.add({
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

        // Update statistics
        attendanceStats[selectedChildId]!['total']++;
        attendanceStats[selectedChildId]![status]++;
      }

      // Calculate percentage
      final stats = attendanceStats[selectedChildId]!;
      if (stats['total'] > 0) {
        stats['percentage'] = (stats['present'] / stats['total'] * 100);
      }
    } catch (e) {
      print('Error loading attendance: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> getFilteredAttendance() {
    final allRecords = attendanceData[selectedChildId] ?? [];

    return allRecords.where((record) {
      final matchesPeriod =
          filterPeriod == 'all' || record['period'] == filterPeriod;
      final matchesStatus =
          filterStatus == 'all' || record['status'] == filterStatus;
      return matchesPeriod && matchesStatus;
    }).toList();
  }

  Widget _buildChildSelector() {
    if (childrenData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.child_care, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No Children Linked',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link students to your account in Profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT CHILD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedChildId,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: childrenData.map((child) {
                final childName = child['name']?.toString() ?? 'Unknown';

                final className =
                    child['classname'] ??
                    child['className'] ??
                    child['class'] ??
                    child['class_name'] ??
                    'No Class';

                return DropdownMenuItem<String>(
                  value: child['id']?.toString(),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 48),
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$childName\n',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: className.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedChildId = value ?? '';
                });
                _loadAttendanceData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT MONTH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final currentIndex = months.indexOf(selectedMonth);
                    if (currentIndex > 0) {
                      setState(() => selectedMonth = months[currentIndex - 1]);
                      _loadAttendanceData();
                    }
                  },
                  icon: Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$selectedMonth ${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final currentIndex = months.indexOf(selectedMonth);
                    if (currentIndex < 11) {
                      setState(() => selectedMonth = months[currentIndex + 1]);
                      _loadAttendanceData();
                    }
                  },
                  icon: Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FILTERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filterPeriod,
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Periods'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('Period 1'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('Period 2'),
                              ),
                              DropdownMenuItem(
                                value: '3',
                                child: Text('Period 3'),
                              ),
                              DropdownMenuItem(
                                value: '4',
                                child: Text('Period 4'),
                              ),
                              DropdownMenuItem(
                                value: '5',
                                child: Text('Period 5'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => filterPeriod = value ?? 'all');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(width: 16),
                // Expanded(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         'Status',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: Colors.grey.shade600,
                //         ),
                //       ),
                //       const SizedBox(height: 4),
                //       Container(
                //         padding: const EdgeInsets.symmetric(horizontal: 8),
                //         decoration: BoxDecoration(
                //           border: Border.all(color: Colors.grey.shade300),
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //         child: DropdownButtonHideUnderline(
                //           child: DropdownButton<String>(
                //             value: filterStatus,
                //             items: [
                //               DropdownMenuItem(
                //                 value: 'all',
                //                 child: Text('All Status'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'present',
                //                 child: Text('Present'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'absent',
                //                 child: Text('Absent'),
                //               ),
                //               DropdownMenuItem(
                //                 value: 'late',
                //                 child: Text('Late'),
                //               ),
                //             ],
                //             onChanged: (value) {
                //               setState(() => filterStatus = value ?? 'all');
                //             },
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    if (selectedChildId.isEmpty ||
        !attendanceStats.containsKey(selectedChildId)) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Select a child to view attendance',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final stats = attendanceStats[selectedChildId]!;
    final selectedChild = childrenData.firstWhere(
      (child) => child['id']?.toString() == selectedChildId,
      orElse: () => childrenData.isNotEmpty ? childrenData.first : {},
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATTENDANCE SUMMARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  radius: 30,
                  child: Text(
                    selectedChild['name']
                            ?.toString()
                            .substring(0, 1)
                            .toUpperCase() ??
                        '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedChild['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedChild['className']?.toString() ??
                            'Unknown Class',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${stats['percentage'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard(
                  'Total',
                  '${stats['total']}',
                  Colors.grey,
                  Icons.calendar_today,
                ),
                _buildStatCard(
                  'Present',
                  '${stats['present']}',
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatCard(
                  'Absent',
                  '${stats['absent']}',
                  Colors.red,
                  Icons.cancel,
                ),
                _buildStatCard(
                  'Late',
                  '${stats['late']}',
                  Colors.orange,
                  Icons.watch_later,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    final filteredRecords = getFilteredAttendance();

    if (filteredRecords.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Attendance Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No attendance data found for the selected filters',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATTENDANCE RECORDS (${filteredRecords.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$selectedMonth ${selectedDate.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRecords.length,
            itemBuilder: (context, index) {
              final record = filteredRecords[index];
              final date = record['date'] as DateTime;
              final status = record['status']?.toString() ?? 'absent';
              final period = record['period']?.toString() ?? '';
              final periodTime = record['periodTime']?.toString() ?? '';

              Color statusColor;
              IconData statusIcon;

              switch (status) {
                case 'present':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'absent':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                case 'late':
                  statusColor = Colors.orange;
                  statusIcon = Icons.watch_later;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.help;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    'Period $period',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatDate(date)} • $periodTime'),
                      Text(
                        'Marked by: ${record['markedBy']?.toString().toUpperCase() ?? 'SYSTEM'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Child Selector
                  _buildChildSelector(),
                  const SizedBox(height: 16),

                  if (childrenData.isNotEmpty) ...[
                    // Month Selector
                    _buildMonthSelector(),
                    const SizedBox(height: 16),

                    // Filters
                    _buildFilters(),
                    const SizedBox(height: 16),

                    // Summary
                    _buildAttendanceSummary(),
                    const SizedBox(height: 16),

                    // Attendance List
                    _buildAttendanceList(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
