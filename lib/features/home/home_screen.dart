import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/class_mode/class_mode_button.dart';
import 'package:quietly/utils/service/dns_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DndService _dndService = DndService();
  bool _isClassMode = false;
  bool _isLoading = false;
  String _userName = '';
  String _userClass = '';
  String _userClassId = '';
  bool _userDataLoaded = false;
  Stream<QuerySnapshot>? _schedulesStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _userName = data?['name']?.toString() ?? 'Student';
          _userClass = data?['classname']?.toString() ?? '';
          _userClassId = data?['classId']?.toString() ?? '';
          _userDataLoaded = true;
          _schedulesStream = _getTodaySchedules();
        });
      }
    } catch (_) {}
  }

  Stream<QuerySnapshot> _getTodaySchedules() {
    if (_userClassId.isEmpty) {
      return const Stream.empty();
    }
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return FirebaseFirestore.instance
        .collection('Classes')
        .doc(_userClassId)
        .collection('Schedules')
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .snapshots();
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Colors.blue;
    if (s.contains('physic')) return Colors.orange;
    if (s.contains('chem')) return Colors.green;
    if (s.contains('english')) return Colors.purple;
    if (s.contains('computer') || s.contains('bca')) return Colors.teal;
    return Colors.indigo;
  }

  Future<void> _toggleClassMode() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (!_isClassMode) {
        if (!await _dndService.hasAccess()) {
          await _dndService.openSettings();
          return;
        }
        await _dndService.setSilent();
      } else {
        await _dndService.restore();
      }
      setState(() => _isClassMode = !_isClassMode);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: const Color.fromARGB(255, 145, 87, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _userDataLoaded ? _userName : 'Loading...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    if (_userClass.isNotEmpty)
                      Text(
                        _userClass,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Class Mode Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Class Mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isClassMode
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isClassMode ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: _isClassMode
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Enable class mode to mute your phone during lessons. Your teacher will see your status.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 20),
                    ClassModeButton(),
                    if (_isClassMode) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_disabled,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Phone is Muted',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your teacher can see that you\'re in class mode',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Today's Schedule
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (!_userDataLoaded)
                      const Center(child: CircularProgressIndicator())
                    else if (_userClassId.isEmpty)
                      const Center(child: Text('Class not assigned'))
                    else
                      StreamBuilder<QuerySnapshot>(
                        stream: _schedulesStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print(
                              'ERROR: Schedule Stream Error: ${snapshot.error}',
                            );
                            return Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text(
                                    'Error loading schedules. Please check if indexes are created.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Error: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'No schedules for today',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          // Sort in memory to avoid needing a composite index
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
                              return _buildScheduleItem(
                                data['subjectTitle'] ?? 'No Title',
                                data['time'] ?? '',
                                _getSubjectColor(data['subjectTitle'] ?? ''),
                              );
                            }).toList(),
                          );
                        },
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

  Widget _buildScheduleItem(String subject, String time, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
