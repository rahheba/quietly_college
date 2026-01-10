// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class TeacherAttendanceModifier extends StatefulWidget {
//   const TeacherAttendanceModifier({Key? key}) : super(key: key);

//   @override
//   State<TeacherAttendanceModifier> createState() =>
//       _TeacherAttendanceModifierState();
// }

// class _TeacherAttendanceModifierState extends State<TeacherAttendanceModifier> {
//   DateTime selectedDate = DateTime.now();
//   String selectedClass = '';
//   String selectedPeriod = '';
//   String searchQuery = '';
//   String filterStatus = 'all';
//   Map<String, String> modifiedRecords = {};
//   String saveStatus = '';
//   bool isLoading = false;
//   bool isLoadingStudents = false;

//   final List<Map<String, String>> periods = [
//     {
//       'id': '1',
//       'name': 'Period 1',
//       'time': '09:30 AM - 10:30 AM',
//       'lateAfter': '10:00 AM',
//     },
//     {
//       'id': '2',
//       'name': 'Period 2',
//       'time': '10:30 AM - 11:30 AM',
//       'lateAfter': '11:00 AM',
//     },
//     {
//       'id': '3',
//       'name': 'Period 3',
//       'time': '11:45 AM - 12:45 PM',
//       'lateAfter': '12:15 PM',
//     },
//     {
//       'id': '4',
//       'name': 'Period 4',
//       'time': '01:15 PM - 02:15 PM',
//       'lateAfter': '01:45 PM',
//     },
//     {
//       'id': '5',
//       'name': 'Period 5',
//       'time': '02:15 PM - 03:15 PM',
//       'lateAfter': '02:45 PM',
//     },
//   ];

//   List<Map<String, dynamic>> classes = [];
//   List<Map<String, dynamic>> students = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadClasses();
//     log("message");
//   }

//   Future<void> _loadClasses() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final classesSnapshot = await FirebaseFirestore.instance
//           .collection('Classes')
//           .get();

//       classes = classesSnapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           'name': data['departmenttitle'] ?? 'Unknown Class',
//           'code': data['departmentcode'] ?? '',
//           'classname': data['classname'] ?? '',
//           'section': _getSectionFromClassname(data['classname']),
//         };
//       }).toList();

//       // Sort classes by name
//       classes.sort(
//         (a, b) => a['name'].toString().compareTo(b['name'].toString()),
//       );
//     } catch (e) {
//       print('Error loading classes: $e');
//       _showErrorSnackbar('Error loading classes: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   // In _loadStudents() - fix to uppercase 'Classes'
//   Future<void> _loadStudents() async {
//     if (selectedClass.isEmpty) {
//       setState(() {
//         students = [];
//       });
//       return;
//     }

//     setState(() {
//       isLoadingStudents = true;
//     });

//     try {
//       final studentsSnapshot = await FirebaseFirestore.instance
//           .collection('Classes') // CHANGE: uppercase 'Classes'
//           .doc(selectedClass)
//           .collection('Students') // Keep uppercase 'Students'
//           .get();

//       students = studentsSnapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           'name': data['name'] ?? 'Unknown Student',
//           'rollNumber': data['rollNumber'] ?? data['id'] ?? '',
//           'deviceId': data['deviceId'] ?? '',
//           'status': 'absent',
//           'autoMarked': false,
//           'entryTime': null,
//           'isPresent': false,
//           'isLate': false,
//         };
//       }).toList();

//       students.sort(
//         (a, b) => a['name'].toString().compareTo(b['name'].toString()),
//       );
//     } catch (e) {
//       print('Error loading students: $e');
//       _showErrorSnackbar('Error loading students: $e');
//     } finally {
//       setState(() {
//         isLoadingStudents = false;
//       });
//     }
//   }

//   String _getSectionFromClassname(String classname) {
//     if (classname.toLowerCase().contains('3rd')) return '3rd Year';
//     if (classname.toLowerCase().contains('2nd')) return '2nd Year';
//     if (classname.toLowerCase().contains('1st')) return '1st Year';
//     if (classname.toLowerCase().contains('bvoc')) return 'BVOC';
//     return 'General';
//   }

//   void _markAttendance(String studentId, String status) {
//     setState(() {
//       modifiedRecords[studentId] = status;
//     });
//   }

//   void _markAllAttendance(String status) {
//     setState(() {
//       for (var student in students) {
//         modifiedRecords[student['id']] = status;
//       }
//     });
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'present':
//         return Colors.green.shade100;
//       case 'absent':
//         return Colors.red.shade100;
//       case 'late':
//         return Colors.orange.shade100;
//       default:
//         return Colors.grey.shade100;
//     }
//   }

//   Color _getStatusTextColor(String status) {
//     switch (status) {
//       case 'present':
//         return Colors.green.shade800;
//       case 'absent':
//         return Colors.red.shade800;
//       case 'late':
//         return Colors.orange.shade800;
//       default:
//         return Colors.grey.shade800;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'present':
//         return Icons.check_circle;
//       case 'absent':
//         return Icons.cancel;
//       case 'late':
//         return Icons.watch_later;
//       default:
//         return Icons.help;
//     }
//   }

//   List<Map<String, dynamic>> getFilteredStudents() {
//     return students.where((student) {
//       final matchesSearch =
//           student['name'].toString().toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           ) ||
//           student['rollNumber'].toString().toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           );
//       final currentStatus = modifiedRecords[student['id']] ?? student['status'];
//       final matchesFilter =
//           filterStatus == 'all' || currentStatus == filterStatus;
//       return matchesSearch && matchesFilter;
//     }).toList();
//   }

//   Future<void> _saveAttendance() async {
//     if (selectedClass.isEmpty || selectedPeriod.isEmpty) {
//       _showErrorSnackbar('Please select class and period first');
//       return;
//     }

//     if (modifiedRecords.isEmpty) {
//       _showErrorSnackbar('No changes to save');
//       return;
//     }

//     setState(() {
//       saveStatus = 'saving';
//     });

//     try {
//       final batch = FirebaseFirestore.instance.batch();
//       final attendanceDate = selectedDate.toIso8601String().split('T')[0];

//       for (var student in students) {
//         final studentId = student['id'];
//         if (modifiedRecords.containsKey(studentId)) {
//           // In _saveAttendance() - fix collection name
//           final attendanceRef = FirebaseFirestore.instance
//               .collection('Classes') // CHANGE: uppercase 'Classes'
//               .doc(selectedClass)
//               .collection('Students') // Keep uppercase 'Students'
//               .doc(studentId)
//               .collection('attendance')
//               .doc('${attendanceDate}_${selectedPeriod}');

//           final attendanceData = {
//             'date': selectedDate,
//             'period': selectedPeriod,
//             'status': modifiedRecords[studentId],
//             'markedBy': 'teacher',
//             'markedAt': FieldValue.serverTimestamp(),
//             'autoMarked': false,
//             'periodTime': periods.firstWhere(
//               (p) => p['id'] == selectedPeriod,
//             )['time'],
//             'lateAfter': periods.firstWhere(
//               (p) => p['id'] == selectedPeriod,
//             )['lateAfter'],
//           };

//           batch.set(attendanceRef, attendanceData);
//         }
//       }

//       await batch.commit();

//       setState(() {
//         saveStatus = 'saved';
//         modifiedRecords.clear();
//       });

//       _showSuccessSnackbar('Attendance saved successfully!');

//       await Future.delayed(const Duration(seconds: 2));
//       setState(() {
//         saveStatus = '';
//       });
//     } catch (e) {
//       print('Error saving attendance: $e');
//       setState(() {
//         saveStatus = 'error';
//       });
//       _showErrorSnackbar('Error saving attendance: $e');
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   int _getStatusCount(String status) {
//     return students.where((s) {
//       final currentStatus = modifiedRecords[s['id']] ?? s['status'];
//       return currentStatus == status;
//     }).length;
//   }

//   Widget _buildClassDropdown() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'SELECT CLASS',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade600,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String>(
//                   value: selectedClass.isEmpty ? null : selectedClass,
//                   isExpanded: true,
//                   hint: const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 12),
//                     child: Text('Choose a class...'),
//                   ),
//                   items: classes.map((cls) {
//                     return DropdownMenuItem<String>(
//                       value: cls['id'],
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               cls['name'],
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 7,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               '${cls['code']} • ${cls['classname']}',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedClass = value ?? '';
//                       modifiedRecords.clear();
//                       saveStatus = '';
//                     });
//                     _loadStudents();
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateSelector() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'DATE',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade600,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 8),
//             InkWell(
//               onTap: () async {
//                 final date = await showDatePicker(
//                   context: context,
//                   initialDate: selectedDate,
//                   firstDate: DateTime(2020),
//                   lastDate: DateTime.now(),
//                 );
//                 if (date != null) {
//                   setState(() {
//                     selectedDate = date;
//                     modifiedRecords.clear();
//                     saveStatus = '';
//                   });
//                 }
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.calendar_today,
//                       size: 4,
//                       color: Colors.grey.shade700,
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                     const Spacer(),
//                     Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPeriodSelector() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'PERIOD',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade600,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               height: 56, // Fixed height
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String>(
//                   value: selectedPeriod.isEmpty ? null : selectedPeriod,
//                   isExpanded: true,
//                   hint: const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 12),
//                     child: Text('Select period...'),
//                   ),
//                   items: periods.map((period) {
//                     return DropdownMenuItem<String>(
//                       value: period['id'],
//                       child: SizedBox(
//                         // ADD SizedBox with fixed height
//                         height: 50, // Fixed height for dropdown items
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 4, // Reduced vertical padding
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment:
//                                 MainAxisAlignment.center, // Center content
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 period['name'] ?? '',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14, // Slightly smaller font
//                                 ),
//                                 maxLines: 1, // Ensure single line
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 2), // Smaller spacing
//                               Text(
//                                 period['time'] ?? '',
//                                 style: TextStyle(
//                                   fontSize: 11, // Smaller font
//                                   color: Colors.grey.shade600,
//                                 ),
//                                 maxLines: 1, // Ensure single line
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedPeriod = value ?? '';
//                       modifiedRecords.clear();
//                       saveStatus = '';
//                     });
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     if (students.isEmpty) return const SizedBox();

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'QUICK ACTIONS',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade600,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => _markAllAttendance('present'),
//                     icon: Icon(Icons.check_circle, color: Colors.green),
//                     label: Text(
//                       'Mark All Present',
//                       style: TextStyle(color: Colors.green),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: Colors.green),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => _markAllAttendance('absent'),
//                     icon: Icon(Icons.cancel, color: Colors.red),
//                     label: Text(
//                       'Mark All Absent',
//                       style: TextStyle(color: Colors.red),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: Colors.red),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => _markAllAttendance('late'),
//                     icon: Icon(Icons.watch_later, color: Colors.orange),
//                     label: Text(
//                       'Mark All Late',
//                       style: TextStyle(color: Colors.orange),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: Colors.orange),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStudentList() {
//     if (selectedClass.isEmpty) {
//       return Card(
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(48),
//           child: Column(
//             children: [
//               Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
//               const SizedBox(height: 16),
//               Text(
//                 'Select a Class',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Choose a class from the dropdown above to view students',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey.shade500),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (isLoadingStudents) {
//       return Card(
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(48),
//           child: Column(
//             children: [
//               CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               Text('Loading students...'),
//             ],
//           ),
//         ),
//       );
//     }

//     if (students.isEmpty) {
//       return Card(
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(48),
//           child: Column(
//             children: [
//               Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
//               const SizedBox(height: 16),
//               Text(
//                 'No Students Found',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'No students are enrolled in this class',
//                 style: TextStyle(color: Colors.grey.shade500),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final filteredStudents = getFilteredStudents();

//     return Column(
//       children: [
//         // Header with search and filter
//         Card(
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         onChanged: (value) =>
//                             setState(() => searchQuery = value),
//                         decoration: InputDecoration(
//                           hintText: 'Search students...',
//                           prefixIcon: Icon(Icons.search),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade300),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           value: filterStatus,
//                           items: const [
//                             DropdownMenuItem(value: 'all', child: Text('All')),
//                             DropdownMenuItem(
//                               value: 'present',
//                               child: Text('Present'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'absent',
//                               child: Text('Absent'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'late',
//                               child: Text('Late'),
//                             ),
//                           ],
//                           onChanged: (value) =>
//                               setState(() => filterStatus = value ?? 'all'),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '${filteredStudents.length} Students',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     Text(
//                       '${modifiedRecords.length} Modified',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: modifiedRecords.isEmpty
//                             ? Colors.grey
//                             : Colors.blue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Students list
//         Card(
//           elevation: 2,
//           child: ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: filteredStudents.length,
//             itemBuilder: (context, index) {
//               final student = filteredStudents[index];
//               final studentId = student['id'] as String;
//               final currentStatus =
//                   modifiedRecords[studentId] ?? student['status'];
//               final isModified = modifiedRecords.containsKey(studentId);

//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: isModified ? Colors.blue.shade50 : Colors.white,
//                   border: Border.all(
//                     color: isModified
//                         ? Colors.blue.shade200
//                         : Colors.grey.shade200,
//                   ),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.indigo.shade100,
//                     child: Text(
//                       student['name'].toString().substring(0, 1).toUpperCase(),
//                       style: TextStyle(
//                         color: Colors.indigo.shade800,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     student['name'],
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     student['rollNumber']?.isNotEmpty == true
//                         ? 'Roll No: ${student['rollNumber']}'
//                         : 'ID: ${student['id']}',
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Status indicator
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(currentStatus),
//                           border: Border.all(
//                             color: _getStatusTextColor(currentStatus),
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               _getStatusIcon(currentStatus),
//                               size: 16,
//                               color: _getStatusTextColor(currentStatus),
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               currentStatus.toUpperCase(),
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: _getStatusTextColor(currentStatus),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Action buttons
//                       PopupMenuButton<String>(
//                         icon: Icon(
//                           Icons.more_vert,
//                           color: Colors.grey.shade600,
//                         ),
//                         itemBuilder: (context) => [
//                           PopupMenuItem(
//                             value: 'present',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.check_circle, color: Colors.green),
//                                 const SizedBox(width: 8),
//                                 Text('Mark Present'),
//                               ],
//                             ),
//                           ),
//                           PopupMenuItem(
//                             value: 'absent',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.cancel, color: Colors.red),
//                                 const SizedBox(width: 8),
//                                 Text('Mark Absent'),
//                               ],
//                             ),
//                           ),
//                           PopupMenuItem(
//                             value: 'late',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.watch_later, color: Colors.orange),
//                                 const SizedBox(width: 8),
//                                 Text('Mark Late'),
//                               ],
//                             ),
//                           ),
//                         ],
//                         onSelected: (value) =>
//                             _markAttendance(studentId, value),
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     // Cycle through statuses on tap
//                     final nextStatus = currentStatus == 'present'
//                         ? 'absent'
//                         : currentStatus == 'absent'
//                         ? 'late'
//                         : 'present';
//                     _markAttendance(studentId, nextStatus);
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSummary() {
//     if (students.isEmpty) return const SizedBox();

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'ATTENDANCE SUMMARY',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade600,
//                 letterSpacing: 1,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 _buildSummaryItem(
//                   'Total',
//                   '${students.length}',
//                   Colors.grey,
//                   Icons.people,
//                 ),
//                 _buildSummaryItem(
//                   'Present',
//                   '${_getStatusCount('present')}',
//                   Colors.green,
//                   Icons.check_circle,
//                 ),
//                 _buildSummaryItem(
//                   'Absent',
//                   '${_getStatusCount('absent')}',
//                   Colors.red,
//                   Icons.cancel,
//                 ),
//                 _buildSummaryItem(
//                   'Late',
//                   '${_getStatusCount('late')}',
//                   Colors.orange,
//                   Icons.watch_later,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryItem(
//     String title,
//     String value,
//     Color color,
//     IconData icon,
//   ) {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 20, color: color),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 10,
//                 color: color,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final modificationCount = modifiedRecords.length;

//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text('Attendance Management'),
//         backgroundColor: Colors.indigo.shade700,
//         actions: [
//           if (modificationCount > 0)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton.icon(
//                 onPressed: _saveAttendance,
//                 icon: const Icon(Icons.save),
//                 label: Text('SAVE ($modificationCount)'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Colors.indigo.shade700,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Selection Section
//                   Column(
//                     children: [
//                       _buildClassDropdown(),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(child: _buildDateSelector()),
//                           const SizedBox(width: 12),
//                           Expanded(child: _buildPeriodSelector()),
//                         ],
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Quick Actions
//                   if (selectedClass.isNotEmpty && students.isNotEmpty)
//                     _buildQuickActions(),

//                   const SizedBox(height: 16),

//                   // Students List
//                   _buildStudentList(),

//                   const SizedBox(height: 16),

//                   // Summary
//                   _buildSummary(),

//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//     );
//   }
// }
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendanceModifier extends StatefulWidget {
  const TeacherAttendanceModifier({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceModifier> createState() =>
      _TeacherAttendanceModifierState();
}

class _TeacherAttendanceModifierState extends State<TeacherAttendanceModifier> {
  DateTime selectedDate = DateTime.now();
  String selectedClass = '';
  String selectedPeriod = '';
  String searchQuery = '';
  String filterStatus = 'all';
  Map<String, String> modifiedRecords = {};
  String saveStatus = '';
  bool isLoading = false;
  bool isLoadingStudents = false;

  final List<Map<String, String>> periods = [
    {
      'id': '1',
      'name': 'Period 1',
      'time': '09:30 AM - 10:30 AM',
      'lateAfter': '10:00 AM',
    },
    {
      'id': '2',
      'name': 'Period 2',
      'time': '10:30 AM - 11:30 AM',
      'lateAfter': '11:00 AM',
    },
    {
      'id': '3',
      'name': 'Period 3',
      'time': '11:45 AM - 12:45 PM',
      'lateAfter': '12:15 PM',
    },
    {
      'id': '4',
      'name': 'Period 4',
      'time': '01:15 PM - 02:15 PM',
      'lateAfter': '01:45 PM',
    },
    {
      'id': '5',
      'name': 'Period 5',
      'time': '02:15 PM - 03:15 PM',
      'lateAfter': '02:45 PM',
    },
  ];

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    log("Initialized");
  }

  Future<void> _loadClasses() async {
    setState(() => isLoading = true);
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .get();
      classes = classesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['departmenttitle'] ?? 'Unknown Class',
          'code': data['departmentcode'] ?? '',
          'classname': data['classname'] ?? '',
          'section': _getSectionFromClassname(data['classname']),
        };
      }).toList();
      classes.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
    } catch (e) {
      print('Error loading classes: $e');
      _showErrorSnackbar('Error loading classes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (selectedClass.isEmpty) {
      setState(() => students = []);
      return;
    }
    setState(() => isLoadingStudents = true);
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .doc(selectedClass)
          .collection('Students')
          .get();

      students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Student',
          'rollNumber': data['rollNumber'] ?? data['id'] ?? '',
          'deviceId': data['deviceId'] ?? '',
          'status': 'absent',
          'autoMarked': false,
          'entryTime': null,
          'isPresent': false,
          'isLate': false,
        };
      }).toList();

      students.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
      await _loadAttendanceRecords();
    } catch (e) {
      print('Error loading students: $e');
      _showErrorSnackbar('Error loading students: $e');
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (selectedClass.isEmpty || selectedPeriod.isEmpty) return;

    try {
      final attendanceDate = selectedDate.toIso8601String().split('T')[0];
      for (var i = 0; i < students.length; i++) {
        final studentId = students[i]['id'];
        final attendanceDoc = await FirebaseFirestore.instance
            .collection('Classes')
            .doc(selectedClass)
            .collection('Students')
            .doc(studentId)
            .collection('attendance')
            .doc('${attendanceDate}_$selectedPeriod')
            .get();

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data();
          if (data != null && data['status'] != null) {
            setState(() => students[i]['status'] = data['status']);
          }
        }
      }
    } catch (e) {
      print('Error loading attendance records: $e');
    }
  }

  String _getSectionFromClassname(String classname) {
    if (classname.toLowerCase().contains('3rd')) return '3rd Year';
    if (classname.toLowerCase().contains('2nd')) return '2nd Year';
    if (classname.toLowerCase().contains('1st')) return '1st Year';
    if (classname.toLowerCase().contains('bvoc')) return 'BVOC';
    return 'General';
  }

  void _markAttendance(String studentId, String status) {
    setState(() => modifiedRecords[studentId] = status);
  }

  void _markAllAttendance(String status) {
    setState(() {
      for (var student in students) {
        modifiedRecords[student['id']] = status;
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade100;
      case 'absent':
        return Colors.red.shade100;
      case 'late':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade800;
      case 'absent':
        return Colors.red.shade800;
      case 'late':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.watch_later;
      default:
        return Icons.help;
    }
  }

  List<Map<String, dynamic>> getFilteredStudents() {
    return students.where((student) {
      final matchesSearch =
          student['name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          student['rollNumber'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
      final currentStatus = modifiedRecords[student['id']] ?? student['status'];
      final matchesFilter =
          filterStatus == 'all' || currentStatus == filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _saveAttendance() async {
    if (selectedClass.isEmpty || selectedPeriod.isEmpty) {
      _showErrorSnackbar('Please select class and period first');
      return;
    }
    if (modifiedRecords.isEmpty) {
      _showErrorSnackbar('No changes to save');
      return;
    }

    setState(() => saveStatus = 'saving');
    try {
      final batch = FirebaseFirestore.instance.batch();
      final attendanceDate = selectedDate.toIso8601String().split('T')[0];

      for (var student in students) {
        final studentId = student['id'];
        if (modifiedRecords.containsKey(studentId)) {
          final attendanceRef = FirebaseFirestore.instance
              .collection('Classes')
              .doc(selectedClass)
              .collection('Students')
              .doc(studentId)
              .collection('attendance')
              .doc('${attendanceDate}_$selectedPeriod');

          final attendanceData = {
            'date': selectedDate,
            'period': selectedPeriod,
            'status': modifiedRecords[studentId],
            'markedBy': 'teacher',
            'markedAt': FieldValue.serverTimestamp(),
            'autoMarked': false,
            'periodTime': periods.firstWhere(
              (p) => p['id'] == selectedPeriod,
            )['time'],
            'lateAfter': periods.firstWhere(
              (p) => p['id'] == selectedPeriod,
            )['lateAfter'],
          };

          batch.set(attendanceRef, attendanceData);

          final studentIndex = students.indexWhere((s) => s['id'] == studentId);
          if (studentIndex != -1) {
            students[studentIndex]['status'] = modifiedRecords[studentId]!;
          }
        }
      }

      await batch.commit();
      setState(() {
        saveStatus = 'saved';
        modifiedRecords.clear();
      });
      _showSuccessSnackbar('Attendance saved successfully!');
      await Future.delayed(const Duration(seconds: 2));
      setState(() => saveStatus = '');
    } catch (e) {
      print('Error saving attendance: $e');
      setState(() => saveStatus = 'error');
      _showErrorSnackbar('Error saving attendance: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _getStatusCount(String status) {
    return students.where((s) {
      final currentStatus = modifiedRecords[s['id']] ?? s['status'];
      return currentStatus == status;
    }).length;
  }

  Widget _buildClassDropdown() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT CLASS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClass.isEmpty ? null : selectedClass,
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Choose a class...'),
                  ),
                  items: classes.map((cls) {
                    return DropdownMenuItem<String>(
                      value: cls['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cls['code']} • ${cls['classname']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value ?? '';
                      modifiedRecords.clear();
                      saveStatus = '';
                    });
                    _loadStudents();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    modifiedRecords.clear();
                    saveStatus = '';
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 4,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PERIOD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod.isEmpty ? null : selectedPeriod,
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Select period...'),
                  ),
                  items: periods.map((period) {
                    return DropdownMenuItem<String>(
                      value: period['id'],
                      child: SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                period['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                period['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value ?? '';
                      modifiedRecords.clear();
                      saveStatus = '';
                    });
                    if (selectedClass.isNotEmpty) {
                      _loadAttendanceRecords();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    if (students.isEmpty) return const SizedBox();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUICK ACTIONS',
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
                  child: OutlinedButton.icon(
                    onPressed: () => _markAllAttendance('present'),
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    label: Text(
                      'Mark All Present',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAllAttendance('absent'),
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      'Mark All Absent',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAllAttendance('late'),
                    icon: Icon(Icons.watch_later, color: Colors.orange),
                    label: Text(
                      'Mark All Late',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (selectedClass.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Select a Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a class from the dropdown above to view students',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoadingStudents) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading students...'),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Students Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No students are enrolled in this class',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final filteredStudents = getFilteredStudents();

    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filterStatus,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                              value: 'present',
                              child: Text('Present'),
                            ),
                            DropdownMenuItem(
                              value: 'absent',
                              child: Text('Absent'),
                            ),
                            DropdownMenuItem(
                              value: 'late',
                              child: Text('Late'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => filterStatus = value ?? 'all'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredStudents.length} Students',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${modifiedRecords.length} Modified',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: modifiedRecords.isEmpty
                            ? Colors.grey
                            : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              final studentId = student['id'] as String;
              final currentStatus =
                  modifiedRecords[studentId] ?? student['status'];
              final isModified = modifiedRecords.containsKey(studentId);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isModified ? Colors.blue.shade50 : Colors.white,
                  border: Border.all(
                    color: isModified
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      student['name'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.indigo.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    student['rollNumber']?.isNotEmpty == true
                        ? 'Roll No: ${student['rollNumber']}'
                        : 'ID: ${student['id']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(currentStatus),
                          border: Border.all(
                            color: _getStatusTextColor(currentStatus),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(currentStatus),
                              size: 16,
                              color: _getStatusTextColor(currentStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusTextColor(currentStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'present',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text('Mark Present'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'absent',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                const SizedBox(width: 8),
                                Text('Mark Absent'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'late',
                            child: Row(
                              children: [
                                Icon(Icons.watch_later, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text('Mark Late'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) =>
                            _markAttendance(studentId, value),
                      ),
                    ],
                  ),
                  onTap: () {
                    final nextStatus = currentStatus == 'present'
                        ? 'absent'
                        : currentStatus == 'absent'
                        ? 'late'
                        : 'present';
                    _markAttendance(studentId, nextStatus);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    if (students.isEmpty) return const SizedBox();
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
                _buildSummaryItem(
                  'Total',
                  '${students.length}',
                  Colors.grey,
                  Icons.people,
                ),
                _buildSummaryItem(
                  'Present',
                  '${_getStatusCount('present')}',
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildSummaryItem(
                  'Absent',
                  '${_getStatusCount('absent')}',
                  Colors.red,
                  Icons.cancel,
                ),
                _buildSummaryItem(
                  'Late',
                  '${_getStatusCount('late')}',
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

  Widget _buildSummaryItem(
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

  @override
  Widget build(BuildContext context) {
    final modificationCount = modifiedRecords.length;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          if (modificationCount > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _saveAttendance,
                icon: const Icon(Icons.save),
                label: Text('SAVE ($modificationCount)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade700,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Column(
                    children: [
                      _buildClassDropdown(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDateSelector()),

                          Expanded(child: _buildPeriodSelector()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedClass.isNotEmpty && students.isNotEmpty)
                    _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildStudentList(),
                  const SizedBox(height: 16),
                  _buildSummary(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
