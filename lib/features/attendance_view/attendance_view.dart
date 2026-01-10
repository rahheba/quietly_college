import 'package:flutter/material.dart';

class StudentAttendanceViewer extends StatefulWidget {
  const StudentAttendanceViewer({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceViewer> createState() =>
      _StudentAttendanceViewerState();
}

class _StudentAttendanceViewerState extends State<StudentAttendanceViewer> {
  String selectedMonth = DateTime.now().month.toString();
  String selectedSubject = 'all';

  // Mock student data - Replace with actual data from API
  final Map<String, String> studentInfo = {
    'id': 'S001',
    'name': 'Alice Johnson',
    'class': 'Computer Science 101',
    'section': 'A',
    'rollNo': '25',
  };

  // Mock subjects - Replace with actual API call
  final List<Map<String, String>> subjects = [
    {'id': 'CS101', 'name': 'Computer Science 101', 'teacher': 'Dr. Smith'},
    {'id': 'CS102', 'name': 'Data Structures', 'teacher': 'Prof. Johnson'},
    {'id': 'CS201', 'name': 'Algorithms', 'teacher': 'Dr. Brown'},
    {'id': 'MATH201', 'name': 'Discrete Mathematics', 'teacher': 'Prof. Davis'},
  ];

  // Mock attendance data - Replace with actual API call
  final List<Map<String, dynamic>> attendanceRecords = [
    {
      'date': '2025-11-11',
      'subject': 'Computer Science 101',
      'subjectId': 'CS101',
      'period': 'Period 1',
      'status': 'present',
      'entryTime': '09:05 AM',
      'markedBy': 'auto',
      'teacher': 'Dr. Smith',
    },
    {
      'date': '2025-11-11',
      'subject': 'Data Structures',
      'subjectId': 'CS102',
      'period': 'Period 2',
      'status': 'present',
      'entryTime': '10:03 AM',
      'markedBy': 'auto',
      'teacher': 'Prof. Johnson',
    },
    {
      'date': '2025-11-11',
      'subject': 'Algorithms',
      'subjectId': 'CS201',
      'period': 'Period 3',
      'status': 'late',
      'entryTime': '11:25 AM',
      'markedBy': 'teacher',
      'teacher': 'Dr. Brown',
    },
    {
      'date': '2025-11-10',
      'subject': 'Computer Science 101',
      'subjectId': 'CS101',
      'period': 'Period 1',
      'status': 'present',
      'entryTime': '09:02 AM',
      'markedBy': 'auto',
      'teacher': 'Dr. Smith',
    },
    {
      'date': '2025-11-10',
      'subject': 'Data Structures',
      'subjectId': 'CS102',
      'period': 'Period 2',
      'status': 'absent',
      'entryTime': null,
      'markedBy': 'teacher',
      'teacher': 'Prof. Johnson',
    },
    {
      'date': '2025-11-09',
      'subject': 'Discrete Mathematics',
      'subjectId': 'MATH201',
      'period': 'Period 4',
      'status': 'present',
      'entryTime': '12:20 PM',
      'markedBy': 'auto',
      'teacher': 'Prof. Davis',
    },
  ];

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
      final recordDate = DateTime.parse(record['date'] as String);
      final matchesMonth = recordDate.month.toString() == selectedMonth;
      final matchesSubject =
          selectedSubject == 'all' || record['subjectId'] == selectedSubject;
      return matchesMonth && matchesSubject;
    }).toList()..sort(
      (a, b) => DateTime.parse(
        b['date'] as String,
      ).compareTo(DateTime.parse(a['date'] as String)),
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

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Student Info Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade600, Colors.indigo.shade400],
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                        ? [Colors.orange.shade400, Colors.orange.shade600]
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
                            Icon(Icons.event, color: Colors.grey.shade600),
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
                            Icon(Icons.cancel, color: Colors.red.shade600),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
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
                                  value: selectedSubject,
                                  decoration: InputDecoration(
                                    labelText: 'Subject',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'all',
                                      child: Flexible(
                                        child: Text(
                                          'All Subjects',
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    ...subjects.map((subject) {
                                      return DropdownMenuItem(
                                        value: subject['id'],
                                        child: Text(subject['name']!),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSubject = value!;
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
                  if (filteredRecords.isEmpty)
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
                                style: TextStyle(color: Colors.grey.shade600),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                          record['subject'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDate(record['date'] as String),
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
                                      borderRadius: BorderRadius.circular(20),
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
                                          (record['status'] as String)[0]
                                                  .toUpperCase() +
                                              (record['status'] as String)
                                                  .substring(1),
                                          style: TextStyle(
                                            color: getStatusTextColor(
                                              record['status'] as String,
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
                                    '${record['period']} • ${record['entryTime'] ?? 'No entry time'}',
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
                                      color: record['markedBy'] == 'auto'
                                          ? Colors.blue.shade50
                                          : Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          record['markedBy'] == 'auto'
                                              ? Icons.smartphone
                                              : Icons.person,
                                          size: 12,
                                          color: record['markedBy'] == 'auto'
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
                                            color: record['markedBy'] == 'auto'
                                                ? Colors.blue.shade700
                                                : Colors.purple.shade700,
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
    );
  }
}
