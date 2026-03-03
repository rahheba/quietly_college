import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quietly/utils/methods/custom_snackbar.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({Key? key}) : super(key: key);

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedClassId;
  String? selectedClassName;
  String? selectedSubjectId;
  String? selectedSubjectName;
  String? selectedPeriodId;
  bool isLoading = false;
  List<Map<String, dynamic>> teacherClasses = [];
  List<Map<String, dynamic>> subjects = [];

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

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore.collection('Classes').get();

      setState(() {
        teacherClasses = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'classname': doc.data()['classname'] ?? 'Unnamed Class',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> _loadSubjects(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('Classes')
          .doc(classId)
          .collection('Subjects')
          .get();

      setState(() {
        subjects = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc.data()['title'] ?? 'Unnamed Subject',
          };
        }).toList();
        selectedSubjectId = null;
        selectedSubjectName = null;
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _saveSchedule() async {
    if (selectedClassId == null ||
        selectedSubjectId == null ||
        selectedPeriodId == null) {
      showCustomSnackBar(
        context: context,
        message: 'Please select all fields',
        status: SnackStatus.error,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final period = periods.firstWhere((p) => p['id'] == selectedPeriodId);
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day);

      await _firestore.collection('Schedules').add({
        'classId': selectedClassId,
        'className': selectedClassName,
        'subjectId': selectedSubjectId,
        'subjectTitle': selectedSubjectName,
        'periodId': selectedPeriodId,
        'periodName': period['name'],
        'time': period['time'],
        'date': Timestamp.fromDate(dateOnly),
        'createdAt': FieldValue.serverTimestamp(),
        'teacherId': _auth.currentUser?.uid,
      });

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Schedule added successfully',
          status: SnackStatus.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving schedule: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to save schedule',
          status: SnackStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Today Schedule'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Class',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select Class'),
                    items: teacherClasses.map((c) {
                      return DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['classname'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedClassId = val;
                        selectedClassName = teacherClasses.firstWhere(
                          (c) => c['id'] == val,
                        )['classname'];
                        _loadSubjects(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Subject',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSubjectId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select Subject'),
                    items: subjects.map((s) {
                      return DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text(s['title'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedSubjectId = val;
                        selectedSubjectName = subjects.firstWhere(
                          (s) => s['id'] == val,
                        )['title'];
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Period',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPeriodId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select Period'),
                    items: periods.map((p) {
                      return DropdownMenuItem(
                        value: p['id'],
                        child: Text('${p['name']} (${p['time']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedPeriodId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
