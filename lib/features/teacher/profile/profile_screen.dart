// import 'dart:convert';
// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:quietly/features/auth/view/login_screen.dart';
// import 'package:quietly/features/profile/add_student_inclass.dart';
// import 'package:quietly/utils/methods/custom_snackbar.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class TeacherProfile extends StatefulWidget {
//   @override
//   _TeacherProfileState createState() => _TeacherProfileState();
// }

// class _TeacherProfileState extends State<TeacherProfile> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   File? _profileImage;
//   String? _savedImage;

//   // User data
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//   List<Map<String, dynamic>> userClasses = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _loadSavedProfileImage();
//   }

//   // Load user data from Firebase
//   Future<void> _loadUserData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       // Get user document
//       final userDoc = await _firestore.collection('Users').doc(user.uid).get();

//       if (userDoc.exists) {
//         setState(() {
//           userData = userDoc.data();
//         });

//         // Load classes if teacher
//         if (userData?['role'] == 'teacher') {
//           await _loadTeacherClasses();
//         }
//       }
//     } catch (e) {
//       print('Error loading user data: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to load profile data',
//           status: SnackStatus.error,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // Load teacher's classes from Firebase
//   Future<void> _loadTeacherClasses() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       final classesSnapshot = await _firestore
//           .collection('Classes')
//           .where('teacherId', isEqualTo: user.uid)
//           .get();

//       setState(() {
//         userClasses = classesSnapshot.docs
//             .map((doc) => {'id': doc.id, ...doc.data()})
//             .toList();
//       });
//     } catch (e) {
//       print('Error loading classes: $e');
//     }
//   }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       File imageFile = File(pickedFile.path);

//       // convert image to base64
//       List<int> imageBytes = await imageFile.readAsBytes();
//       String base64Image = base64Encode(imageBytes);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('teacher_profile_image', base64Image);

//       setState(() {
//         _profileImage = imageFile;
//       });
//     }
//   }

//   Future<void> _loadSavedProfileImage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final imageString = prefs.getString('teacher_profile_imagep');

//     if (imageString != null) {
//       final bytes = base64Decode(imageString);
//       final tempDir = Directory.systemTemp;
//       final tempFile = await File('${tempDir.path}/profile.png').create();
//       await tempFile.writeAsBytes(bytes);

//       setState(() {
//         _profileImage = tempFile;
//       });
//     }
//   }

//   // Update user profile
//   Future<void> _updateProfile(Map<String, dynamic> updates) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       await _firestore.collection('Users').doc(user.uid).update(updates);

//       setState(() {
//         userData = {...?userData, ...updates};
//       });

//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Profile updated successfully',
//           status: SnackStatus.success,
//         );
//       }
//     } catch (e) {
//       print('Error updating profile: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to update profile',
//           status: SnackStatus.error,
//         );
//       }
//     }
//   }

//   // Create new class
//   Future<void> _createClass(Map<String, dynamic> classData) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       await _firestore.collection('Classes').add({
//         ...classData,
//         'teacherId': user.uid,
//         'teacherName': userData?['name'] ?? '',
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       await _loadTeacherClasses();

//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Class created successfully',
//           status: SnackStatus.success,
//         );
//       }
//     } catch (e) {
//       print('Error creating class: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to create class',
//           status: SnackStatus.error,
//         );
//       }
//     }
//   }

//   // Update class
//   Future<void> _updateClass(
//     String classId,
//     Map<String, dynamic> updates,
//   ) async {
//     try {
//       await _firestore.collection('Classes').doc(classId).update(updates);
//       await _loadTeacherClasses();

//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Class updated successfully',
//           status: SnackStatus.success,
//         );
//       }
//     } catch (e) {
//       print('Error updating class: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to update class',
//           status: SnackStatus.error,
//         );
//       }
//     }
//   }

//   // Delete class
//   Future<void> _deleteClass(String classId) async {
//     try {
//       await _firestore.collection('Classes').doc(classId).delete();
//       await _loadTeacherClasses();

//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Class deleted successfully',
//           status: SnackStatus.success,
//         );
//       }
//     } catch (e) {
//       print('Error deleting class: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to delete class',
//           status: SnackStatus.error,
//         );
//       }
//     }
//   }

//   // Send notification to class
//   Future<void> _sendNotification(
//     String classId,
//     String title,
//     String message,
//   ) async {
//     try {
//       await _firestore.collection('Notifications').add({
//         'classId': classId,
//         'title': title,
//         'message': message,
//         'senderId': _auth.currentUser?.uid,
//         'senderName': userData?['name'] ?? '',
//         'timestamp': FieldValue.serverTimestamp(),
//         'read': false,
//       });

//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Notification sent successfully',
//           status: SnackStatus.success,
//         );
//       }
//     } catch (e) {
//       print('Error sending notification: $e');
//       if (mounted) {
//         showCustomSnackBar(
//           context: context,
//           message: 'Failed to send notification',
//           status: SnackStatus.error,
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Profile'),
//           backgroundColor: Colors.purple,
//           foregroundColor: Colors.white,
//         ),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final isTeacher = userData?['role'] == 'teacher';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Profile'),
//         backgroundColor: Colors.purple,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(icon: Icon(Icons.refresh), onPressed: _loadUserData),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadUserData,
//         child: SingleChildScrollView(
//           physics: AlwaysScrollableScrollPhysics(),
//           child: Column(
//             children: [
//               SizedBox(height: 32),

//               // Profile Picture
//               // CircleAvatar(
//               //   radius: 60,
//               //   backgroundColor: Colors.purple,
//               //   child: Text(
//               //     (userData?['name'] ?? 'U')[0].toUpperCase(),
//               //     style: TextStyle(fontSize: 40, color: Colors.white),
//               //   ),
//               // ),
//               Center(
//                 child: Stack(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.white.withOpacity(0.3),
//                             blurRadius: 20,
//                             offset: Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: CircleAvatar(
//                         radius: 60,
//                         backgroundColor: Colors.purple,
//                         backgroundImage: _profileImage != null
//                             ? FileImage(_profileImage!)
//                             : null,
//                         child: _profileImage == null
//                             ? Text(
//                                 userData?['name']?.isNotEmpty == true
//                                     ? userData!['name'][0].toUpperCase()
//                                     : 'U',
//                                 style: TextStyle(
//                                   fontSize: 48,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : null,
//                       ),
//                     ),

//                     // Camera Icon — Clickable
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: _pickImage,
//                         child: Container(
//                           padding: EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.purple,
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 3),
//                           ),
//                           child: Icon(
//                             Icons.camera_alt,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16),

//               // User Info
//               Text(
//                 userData?['name'] ?? 'User',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 userData?['email'] ?? '',
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//               ),
//               SizedBox(height: 8),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: isTeacher ? Colors.purple : Colors.blue,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   isTeacher ? 'Teacher' : 'Student',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 32),

//               // Profile Info Cards
//               _buildInfoCard(
//                 icon: Icons.person,
//                 title: 'Username',
//                 value: userData?['name'] ?? 'N/A',
//               ),
//               _buildInfoCard(
//                 icon: Icons.email,
//                 title: 'Email',
//                 value: userData?['email'] ?? 'N/A',
//               ),
//               _buildInfoCard(
//                 icon: Icons.badge,
//                 title: 'Role',
//                 value: isTeacher ? 'Teacher' : 'Student',
//               ),

//               // Teacher-specific info
//               if (isTeacher) ...[
//                 _buildInfoCard(
//                   icon: Icons.class_,
//                   title: 'My Classes',
//                   value: '${userClasses.length} Classes',
//                 ),
//               ],

//               SizedBox(height: 16),

//               // Teacher-specific buttons
//               if (isTeacher) ...[
//                 _buildButton(
//                   context,
//                   label: 'Manage Classes',
//                   icon: Icons.class_,
//                   color: Colors.blue,
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => CreateClassPage(),
//                       ),
//                     );
//                   },
//                 ),
//                 SizedBox(height: 12),
//                 _buildButton(
//                   context,
//                   label: 'Send Notification',
//                   icon: Icons.notifications_active_outlined,
//                   color: Colors.orange,
//                   onPressed: () => _showNotificationDialog(context),
//                 ),
//                 SizedBox(height: 12),
//               ],

//               // Edit Profile Button
//               _buildButton(
//                 context,
//                 label: 'Edit Profile',
//                 icon: Icons.edit,
//                 color: Colors.purple,
//                 onPressed: () => _showEditProfileDialog(context),
//               ),
//               SizedBox(height: 12),

//               // Logout Button
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: OutlinedButton(
//                     onPressed: () => _showLogoutDialog(context),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: Colors.red, width: 2),
//                       foregroundColor: Colors.red,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       'Logout',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(
//     BuildContext context, {
//     required String label,
//     IconData? icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16),
//       child: SizedBox(
//         width: double.infinity,
//         height: 50,
//         child: ElevatedButton.icon(
//           onPressed: onPressed,
//           icon: icon != null ? Icon(icon) : SizedBox(),
//           label: Text(
//             label,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.purple.shade50,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: Colors.purple, size: 24),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Edit Profile Dialog
//   void _showEditProfileDialog(BuildContext context) {
//     final _nameController = TextEditingController(text: userData?['name']);
//     final _emailController = TextEditingController(text: userData?['email']);
//     final _formKey = GlobalKey<FormState>();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.edit, color: Colors.purple),
//             SizedBox(width: 12),
//             Text('Edit Profile'),
//           ],
//         ),
//         content: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Name',
//                   prefixIcon: Icon(Icons.person),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your name';
//                   }
//                   if (value.length < 3) {
//                     return 'Name must be at least 3 characters';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   prefixIcon: Icon(Icons.person),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }

//                   return null;
//                 },
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (_formKey.currentState!.validate()) {
//                 await _updateProfile({
//                   'name': _nameController.text.trim(),
//                   'email': _emailController.text.trim(),
//                 });
//                 Navigator.pop(context);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.purple,
//               foregroundColor: Colors.white,
//             ),
//             child: Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Manage Classes Dialog
//   void _showManageClassesDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.class_, color: Colors.blue),
//               SizedBox(width: 12),
//               Text('Manage My Classes'),
//             ],
//           ),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     _showCreateClassDialog(context);
//                   },
//                   icon: Icon(Icons.add),
//                   label: Text('Create New Class'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'My Classes (${userClasses.length})',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 8),
//                 Container(
//                   height: 200,
//                   child: userClasses.isEmpty
//                       ? Center(
//                           child: Text(
//                             'No classes yet',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                         )
//                       : ListView.builder(
//                           itemCount: userClasses.length,
//                           itemBuilder: (context, index) {
//                             final classData = userClasses[index];
//                             return Card(
//                               margin: EdgeInsets.symmetric(vertical: 4),
//                               child: ListTile(
//                                 leading: Icon(Icons.class_, color: Colors.blue),
//                                 title: Text(classData['className'] ?? ''),
//                                 subtitle: Text(
//                                   '${(classData['studentDeviceIds'] as List?)?.length ?? 0} students',
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.edit,
//                                         color: Colors.orange,
//                                       ),
//                                       onPressed: () {
//                                         Navigator.pop(context);
//                                         _showEditClassDialog(
//                                           context,
//                                           classData,
//                                         );
//                                       },
//                                     ),
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.delete,
//                                         color: Colors.red,
//                                       ),
//                                       onPressed: () async {
//                                         await _deleteClass(classData['id']);
//                                         Navigator.pop(context);
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Create Class Dialog
//   void _showCreateClassDialog(BuildContext context) {
//     final TextEditingController _classNameController = TextEditingController();
//     final TextEditingController _subjectController = TextEditingController();
//     final TextEditingController _deviceIdController = TextEditingController();

//     List<String> students = [];

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, dialogSetState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: Row(
//                 children: [
//                   Icon(Icons.add_circle, color: Colors.blue),
//                   SizedBox(width: 12),
//                   Text(
//                     'Create New Class',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),

//               // CONTENT
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     /// CLASS NAME
//                     TextField(
//                       controller: _classNameController,
//                       decoration: InputDecoration(
//                         labelText: 'Class Name',
//                         hintText: 'e.g., 9A Mathematics',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: 12),

//                     /// SUBJECT
//                     TextField(
//                       controller: _subjectController,
//                       decoration: InputDecoration(
//                         labelText: 'Subject',
//                         hintText: 'e.g., Mathematics, Science',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: 16),

//                     /// STUDENT ID INPUT + ADD BUTTON
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _deviceIdController,
//                             decoration: InputDecoration(
//                               labelText: 'Student Device ID',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(horizontal: 12),
//                           ),
//                           onPressed: () {
//                             final id = _deviceIdController.text.trim();

//                             if (id.isNotEmpty && !students.contains(id)) {
//                               dialogSetState(() {
//                                 students.add(id);
//                                 _deviceIdController.clear();
//                               });
//                             }
//                           },
//                           child: Icon(Icons.add),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 12),

//                     /// STUDENTS LIST
//                     Text(
//                       'Students (${students.length})',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),

//                     SizedBox(height: 8),

//                     Container(
//                       height: 150,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: students.isEmpty
//                           ? Center(child: Text("No students added"))
//                           : ListView.builder(
//                               itemCount: students.length,
//                               itemBuilder: (context, index) {
//                                 return ListTile(
//                                   leading: Icon(
//                                     Icons.person,
//                                     color: Colors.green,
//                                   ),
//                                   title: Text(students[index]),
//                                   trailing: IconButton(
//                                     icon: Icon(Icons.delete, color: Colors.red),
//                                     onPressed: () {
//                                       dialogSetState(() {
//                                         students.removeAt(index);
//                                       });
//                                     },
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),

//               // ACTION BUTTONS
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final className = _classNameController.text.trim();
//                     final subject = _subjectController.text.trim();

//                     if (className.isEmpty || subject.isEmpty) return;

//                     // Firestore method call
//                     await _createClass({
//                       'className': className,
//                       'subject': subject,
//                       'studentDeviceIds': students,
//                     });

//                     Navigator.pop(context);
//                   },
//                   child: Text('Create Class'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // Edit Class Dialog
//   void _showEditClassDialog(
//     BuildContext context,
//     Map<String, dynamic> classData,
//   ) {
//     final _deviceIdController = TextEditingController();
//     List<String> students = List.from(classData['studentDeviceIds'] ?? []);

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, dialogSetState) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.edit, color: Colors.orange),
//               SizedBox(width: 12),
//               Text('Edit ${classData['className']}'),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: Icon(Icons.class_, color: Colors.purple),
//                   title: Text('Class'),
//                   subtitle: Text(classData['className']),
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.subject, color: Colors.purple),
//                   title: Text('Subject'),
//                   subtitle: Text(classData['subject']),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _deviceIdController,
//                         decoration: InputDecoration(
//                           labelText: 'Add Student Device ID',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         final id = _deviceIdController.text.trim();
//                         if (id.isNotEmpty && !students.contains(id)) {
//                           dialogSetState(() {
//                             students.add(id);
//                             _deviceIdController.clear();
//                           });
//                         }
//                       },
//                       child: Icon(Icons.add),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12),
//                 Text('Students (${students.length})'),
//                 Container(
//                   height: 150,
//                   child: ListView.builder(
//                     itemCount: students.length,
//                     itemBuilder: (context, index) => ListTile(
//                       leading: Icon(Icons.person, color: Colors.green),
//                       title: Text(students[index]),
//                       trailing: IconButton(
//                         icon: Icon(Icons.delete, color: Colors.red),
//                         onPressed: () {
//                           dialogSetState(() => students.removeAt(index));
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await _updateClass(classData['id'], {
//                   'studentDeviceIds': students,
//                 });
//                 Navigator.pop(context);
//               },
//               child: Text('Save Changes'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Send Notification Dialog
//   void _showNotificationDialog(BuildContext context) {
//     final _titleController = TextEditingController();
//     final _messageController = TextEditingController();
//     final _formKey = GlobalKey<FormState>();
//     Map<String, dynamic>? selectedClass;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Row(
//             children: [
//               Icon(Icons.notifications, color: Colors.orange),
//               SizedBox(width: 12),
//               Text('Send Notification'),
//             ],
//           ),
//           content: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DropdownButtonFormField<Map<String, dynamic>>(
//                   decoration: InputDecoration(
//                     labelText: 'Select Class',
//                     prefixIcon: Icon(Icons.class_),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   value: selectedClass,
//                   items: userClasses.map((classData) {
//                     return DropdownMenuItem(
//                       value: classData,
//                       child: Text(classData['className']),
//                     );
//                   }).toList(),
//                   onChanged: (value) => setState(() => selectedClass = value),
//                   validator: (value) =>
//                       value == null ? 'Please select a class' : null,
//                 ),
//                 SizedBox(height: 16),
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: InputDecoration(
//                     labelText: 'Title',
//                     prefixIcon: Icon(Icons.title),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Enter a title' : null,
//                 ),
//                 SizedBox(height: 16),
//                 TextFormField(
//                   controller: _messageController,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     labelText: 'Message',
//                     prefixIcon: Icon(Icons.message),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   validator: (v) => v!.isEmpty ? 'Enter a message' : null,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 if (_formKey.currentState!.validate()) {
//                   await _sendNotification(
//                     selectedClass!['id'],
//                     _titleController.text,
//                     _messageController.text,
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//               ),
//               child: Text('Send'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Logout Dialog
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(Icons.logout, color: Colors.red),
//             SizedBox(width: 12),
//             Text('Logout'),
//           ],
//         ),
//         content: Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _auth.signOut();
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (context) => LoginPage()),
//                 (route) => false,
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: Text('Logout'),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quietly/features/admin/class/classlist_screen.dart';
import 'package:quietly/features/auth/view/login_screen.dart';
import 'package:quietly/utils/methods/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherProfile extends StatefulWidget {
  @override
  _TeacherProfileState createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _profileImage;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<Map<String, dynamic>> userClasses = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedProfileImage();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('Users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });

        if (userData?['role'] == 'teacher') {
          await _loadTeacherClasses();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to load profile data',
          status: SnackStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTeacherClasses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final classesSnapshot = await _firestore.collection('Classes').get();

      setState(() {
        userClasses = classesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacher_profile_image', base64Image);

      setState(() {
        _profileImage = imageFile;
      });
    }
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imageString = prefs.getString('teacher_profile_image');

    if (imageString != null) {
      final bytes = base64Decode(imageString);
      final tempDir = Directory.systemTemp;
      final tempFile = await File('${tempDir.path}/profile.png').create();
      await tempFile.writeAsBytes(bytes);

      setState(() {
        _profileImage = tempFile;
      });
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('Users').doc(user.uid).update(updates);

      setState(() {
        userData = {...?userData, ...updates};
      });

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Profile updated successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to update profile',
          status: SnackStatus.error,
        );
      }
    }
  }

  Future<void> _createClass(Map<String, dynamic> classData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create the class document
      await _firestore.collection('Classes').add({
        ...classData,
        'teacherId': user.uid,
        'teacherName': userData?['name'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'studentIds': [], // Initialize with empty array
      });

      await _loadTeacherClasses();

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Class created successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error creating class: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to create class',
          status: SnackStatus.error,
        );
      }
    }
  }

  Future<void> _updateClass(
    String classId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('Classes').doc(classId).update(updates);
      await _loadTeacherClasses();

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Class updated successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error updating class: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to update class',
          status: SnackStatus.error,
        );
      }
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      // Delete all students from this class first
      final studentsSnapshot = await _firestore
          .collection('Students')
          // .where('classId', isEqualTo: classId)
          .get();

      for (var doc in studentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the class
      await _firestore.collection('Classes').doc(classId).delete();
      await _loadTeacherClasses();

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Class deleted successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error deleting class: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to delete class',
          status: SnackStatus.error,
        );
      }
    }
  }

  // Get student details from Students collection
  Future<List<Map<String, dynamic>>> _getStudentDetails(String classId) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('Students')
          .where('classId', isEqualTo: classId)
          .get();

      List<Map<String, dynamic>> students = [];

      for (var doc in studentsSnapshot.docs) {
        final studentData = doc.data();

        // Get user details from Users collection
        final userDoc = await _firestore
            .collection('Users')
            .doc(studentData['studentId'])
            .get();

        if (userDoc.exists) {
          students.add({
            'studentDocId': doc.id, // Students collection document ID
            'studentId': studentData['studentId'],
            'name': userDoc.data()?['name'] ?? 'Unknown',
            'email': userDoc.data()?['email'] ?? '',
            'classId': classId,
          });
        }
      }

      return students;
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // Add student to class (save to Students collection)
  Future<void> _addStudentToClass(String classId, String studentUserId) async {
    try {
      // Check if student already exists in this class
      final existingStudent = await _firestore
          .collection('Students')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: studentUserId)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        showCustomSnackBar(
          context: context,
          message: 'Student already in this class',
          status: SnackStatus.warning,
        );
        return;
      }

      // Get student details from Users collection
      final userDoc = await _firestore
          .collection('Users')
          .doc(studentUserId)
          .get();

      if (!userDoc.exists) {
        showCustomSnackBar(
          context: context,
          message: 'Student not found',
          status: SnackStatus.error,
        );
        return;
      }

      final userData = userDoc.data();

      // Get class details
      final classDoc = await _firestore
          .collection('Classes')
          .doc(classId)
          .get();
      if (!classDoc.exists) {
        showCustomSnackBar(
          context: context,
          message: 'Class not found',
          status: SnackStatus.error,
        );
        return;
      }

      final classData = classDoc.data();

      // Add to Students collection
      await _firestore.collection('Students').add({
        'studentId': studentUserId,
        'studentName': userData?['name'] ?? 'Unknown',
        'studentEmail': userData?['email'] ?? '',
        'classId': classId,
        'className': classData?['className'] ?? '',
        'teacherId': _auth.currentUser?.uid ?? '',
        'teacherName': this.userData?['name'] ?? '',
        'enrolledAt': FieldValue.serverTimestamp(),
        'status': 1, // Active
      });

      // Also update the class document to include student ID in studentIds array
      List<String> currentStudents = List<String>.from(
        classData?['studentIds'] ?? [],
      );

      if (!currentStudents.contains(studentUserId)) {
        currentStudents.add(studentUserId);
        await _firestore.collection('Classes').doc(classId).update({
          'studentIds': currentStudents,
        });
      }

      await _loadTeacherClasses();

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Student added successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error adding student: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to add student',
          status: SnackStatus.error,
        );
      }
    }
  }

  // Remove student from class (delete from Students collection)
  Future<void> _removeStudentFromClass(
    String classId,
    String studentDocId, // Students collection document ID
    String studentUserId, // Users collection user ID
  ) async {
    try {
      // Remove from Students collection
      await _firestore.collection('Students').doc(studentDocId).delete();

      // Remove from class's studentIds array
      final classDoc = await _firestore
          .collection('Classes')
          .doc(classId)
          .get();
      if (classDoc.exists) {
        List<String> currentStudents = List<String>.from(
          classDoc.data()?['studentIds'] ?? [],
        );

        currentStudents.remove(studentUserId);

        await _firestore.collection('Classes').doc(classId).update({
          'studentIds': currentStudents,
        });
      }

      await _loadTeacherClasses();

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Student removed successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error removing student: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to remove student',
          status: SnackStatus.error,
        );
      }
    }
  }

  Future<void> _sendNotification(
    String classId,
    String title,
    String message,
  ) async {
    try {
      await _firestore.collection('Notifications').add({
        'classId': classId,
        'title': title,
        'message': message,
        'senderId': _auth.currentUser?.uid,
        'senderName': userData?['name'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Notification sent successfully',
          status: SnackStatus.success,
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to send notification',
          status: SnackStatus.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isTeacher = userData?['role'] == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadUserData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 32),

              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.purple,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? Text(
                                userData?['name']?.isNotEmpty == true
                                    ? userData!['name'][0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // User Info
              Text(
                userData?['name'] ?? 'User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                userData?['email'] ?? '',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isTeacher ? Colors.purple : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTeacher ? 'Teacher' : 'Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Profile Info Cards
              _buildInfoCard(
                icon: Icons.person,
                title: 'Username',
                value: userData?['name'] ?? 'N/A',
              ),
              _buildInfoCard(
                icon: Icons.email,
                title: 'Email',
                value: userData?['email'] ?? 'N/A',
              ),
              _buildInfoCard(
                icon: Icons.badge,
                title: 'Role',
                value: isTeacher ? 'Teacher' : 'Student',
              ),

              if (isTeacher) ...[
                _buildInfoCard(
                  icon: Icons.class_,
                  title: 'My Classes',
                  value: '${userClasses.length} Classes',
                ),
              ],

              SizedBox(height: 16),

              // Teacher-specific buttons
              if (isTeacher) ...[
                // _buildButton(
                //   context,
                //   label: 'Create New Class',
                //   icon: Icons.add_circle,
                //   color: Colors.blue,
                //   onPressed: () => _showCreateClassDialog(context),
                // ),
                // SizedBox(height: 12),
                _buildButton(
                  context,
                  label: 'Create New Classes & Add Students',
                  icon: Icons.people,
                  color: Colors.green,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassesListScreen(showAppBar: true),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                _buildButton(
                  context,
                  label: 'Send Notification',
                  icon: Icons.notifications_active,
                  color: Colors.orange,
                  onPressed: () => _showNotificationDialog(context),
                ),
                SizedBox(height: 12),
              ],

              // Edit Profile Button
              _buildButton(
                context,
                label: 'Edit Profile',
                icon: Icons.edit,
                color: Colors.purple,
                onPressed: () => _showEditProfileDialog(context),
              ),
              SizedBox(height: 12),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon) : SizedBox(),
          label: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.purple, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final _nameController = TextEditingController(text: userData?['name']);
    final _emailController = TextEditingController(text: userData?['email']);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.purple),
            SizedBox(width: 12),
            Text('Edit Profile'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _updateProfile({
                  'name': _nameController.text.trim(),
                  'email': _emailController.text.trim(),
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // View Classes and Students Dialog - Updated to use Students collection
  void _showManageClassesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.green),
            SizedBox(width: 12),
            Text('My Classes & Students'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: userClasses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No classes yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: userClasses.length,
                  itemBuilder: (context, index) {
                    final classData = userClasses[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: Icon(Icons.class_, color: Colors.blue),
                        title: Text(
                          classData['classname'] ?? 'Unnamed Class',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${(classData['studentIds'] as List?)?.length ?? 0} students',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.person_add, color: Colors.green),
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddStudentDialog(context, classData);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Class'),
                                    content: Text(
                                      'Are you sure you want to delete this class? This will also remove all students from this class.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _deleteClass(classData['id']);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getStudentDetails(classData['id']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No students in this class',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: snapshot.data!.map((student) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        student['name'][0].toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(student['name']),
                                    subtitle: Text(student['email']),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await _removeStudentFromClass(
                                          classData['id'],
                                          student['studentDocId'],
                                          student['studentId'],
                                        );

                                        Navigator.pop(context);
                                        _showManageClassesDialog(context);
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Create Class Dialog
  void _showCreateClassDialog(BuildContext context) {
    final TextEditingController _classNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.blue),
            SizedBox(width: 12),
            Text('Create New Class'),
          ],
        ),
        content: TextField(
          controller: _classNameController,
          decoration: InputDecoration(
            labelText: 'Class Name',
            hintText: 'e.g., Grade 9A, Physics 101',
            prefixIcon: Icon(Icons.class_),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final className = _classNameController.text.trim();

              if (className.isEmpty) {
                showCustomSnackBar(
                  context: context,
                  message: 'Please enter a class name',
                  status: SnackStatus.error,
                );
                return;
              }

              await _createClass({'className': className});

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  // Add Student to Class Dialog
  void _showAddStudentDialog(
    BuildContext context,
    Map<String, dynamic> classData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.green),
            SizedBox(width: 12),
            Text('Add Student to ${classData['className']}'),
          ],
        ),
        content: FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('Users')
              .where('role', isEqualTo: 'student')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No students available');
            }

            final allStudents = snapshot.data!.docs;
            final currentStudentIds = List<String>.from(
              classData['studentIds'] ?? [],
            );

            // Filter out students already in the class
            final availableStudents = allStudents
                .where((doc) => !currentStudentIds.contains(doc.id))
                .toList();

            if (availableStudents.isEmpty) {
              return Text('All students are already in this class');
            }

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: availableStudents.length,
                itemBuilder: (context, index) {
                  final student = availableStudents[index];
                  final studentData = student.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        (studentData['name'] ?? 'S')[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(studentData['name'] ?? 'Unknown'),
                    subtitle: Text(studentData['email'] ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await _addStudentToClass(classData['id'], student.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Add'),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _messageController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    Map<String, dynamic>? selectedClass;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.orange),
              SizedBox(width: 12),
              Text('Send Notification'),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(
                    labelText: 'Select Class',
                    prefixIcon: Icon(Icons.class_),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedClass,
                  items: userClasses.map((classData) {
                    return DropdownMenuItem(
                      value: classData,
                      child: Text(classData['classname']),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedClass = value),
                  validator: (value) =>
                      value == null ? 'Please select a class' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    prefixIcon: Icon(Icons.message),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter a message' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _sendNotification(
                    selectedClass!['id'],
                    _titleController.text,
                    _messageController.text,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
