import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/auth/view/login_screen.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool smsNotifications = false;

  Map<String, dynamic>? parentData;
  List<Map<String, dynamic>> childrenData = [];
  bool isLoading = true;
  List<DocumentSnapshot> classes = [];
  String? className;

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get parent data from Users collection where role is "parent"
        final parentDoc = await _firestore
            .collection('Users')
            .where('email', isEqualTo: user.email)
            .where('role', isEqualTo: 'parent')
            .limit(1)
            .get();

        if (parentDoc.docs.isNotEmpty) {
          parentData =
              parentDoc.docs.first.data() as Map<String, dynamic>? ?? {};
          parentData!['id'] = parentDoc.docs.first.id;

          // Update text controllers with actual data
          _nameController.text = parentData!['name']?.toString() ?? '';
          _emailController.text = parentData!['email']?.toString() ?? '';
          _phoneController.text = parentData!['phone']?.toString() ?? '';

          // Load all classes first
          await _loadClasses();

          // Load children data for this parent
          await _loadChildrenData(parentData!['id']);
        }
      }
    } catch (e) {
      print('Error loading parent data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classesSnapshot = await _firestore.collection('Classes').get();
      classes = classesSnapshot.docs;
    } catch (e) {
      print('Error loading classes: $e');
    }
  }

  Future<void> _loadChildrenData(String parentId) async {
    try {
      childrenData.clear();

      // Query Students subcollection in each class where parentid matches
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

          // Get classname from the student document itself
          // The classname field is in the Students document
          final className =
              studentData['classname']?.toString() ?? 'Unknown Class';
          // studentData['className'] = className;

          childrenData.add(studentData);
        }
      }
    } catch (e) {
      print('Error loading children data: $e');
    }
  }

  Future<void> _updateParentProfile() async {
    try {
      if (parentData == null || parentData!['id'] == null) return;

      await _firestore.collection('Users').doc(parentData!['id']).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'updatedAt': DateTime.now(),
      });

      // Update parent info in all associated student records across all classes
      final batch = _firestore.batch();
      for (var child in childrenData) {
        final childRef = _firestore
            .collection('Classes')
            .doc(child['classId']?.toString())
            .collection('Students')
            .doc(child['id']?.toString());
        batch.update(childRef, {
          'parentName': _nameController.text,
          'parentEmail': _emailController.text,
        });
      }

      if (childrenData.isNotEmpty) {
        await batch.commit();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Reload data
      await _loadParentData();
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addChild() async {
    if (parentData == null) return;

    // Show add child dialog
    showDialog(
      context: context,
      builder: (context) => AddChildDialog(
        parentId: parentData!['id']?.toString() ?? '',
        parentName: _nameController.text,
        parentEmail: _emailController.text,
        classes: classes,
        onChildAdded: () {
          _loadChildrenData(parentData!['id']);
        },
      ),
    );
  }

  Future<void> _editChild(Map<String, dynamic> child) async {
    // Show edit child dialog
    showDialog(
      context: context,
      builder: (context) => EditChildDialog(
        childData: child,
        onChildUpdated: () {
          _loadChildrenData(parentData?['id']?.toString() ?? '');
        },
      ),
    );
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final childId = child['id']?.toString();
    final classId = child['classId']?.toString();
    final childName = child['name']?.toString() ?? 'this child';

    if (childId == null || classId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Child'),
        content: Text(
          'Are you sure you want to remove $childName from your profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore
                    .collection('Classes')
                    .doc(classId)
                    .collection('Students')
                    .doc(childId)
                    .update({
                      'parentid': '',
                      'parentName': '',
                      'parentEmail': '',
                    });

                setState(() {
                  childrenData.removeWhere(
                    (c) => c['id']?.toString() == childId,
                  );
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Child removed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to remove child'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEF3C7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB45309)),
        ),
      );
    }

    final initials = _nameController.text.isNotEmpty
        ? _nameController.text
              .split(' ')
              .where((word) => word.isNotEmpty)
              .map((word) => word[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'PA';

    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _updateParentProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB45309),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Parent Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Parent Account',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Children',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${childrenData.length} child${childrenData.length != 1 ? 'ren' : ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (childrenData.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No children linked to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...childrenData.map((child) {
                            final childName =
                                child['name']?.toString() ?? 'Unknown';
                            // final className =

                            final initials = childName
                                .split(' ')
                                .where((word) => word.isNotEmpty)
                                .map((word) => word[0])
                                .take(2)
                                .join()
                                .toUpperCase();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildChildItem(
                                childName,
                                className ?? 'N/A',
                                initials,
                                onEdit: () => _editChild(child),
                                onDelete: () => _deleteChild(child),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    const SizedBox(height: 16),
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
                      'Notification Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive app notifications',
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    _buildSwitchTile(
                      title: 'Email Notifications',
                      subtitle: 'Receive updates via email',
                      value: emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          emailNotifications = value;
                        });
                      },
                    ),
                    const Divider(),
                    _buildSwitchTile(
                      title: 'SMS Notifications',
                      subtitle: 'Receive text messages',
                      value: smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          smsNotifications = value;
                        });
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
                  children: [
                    _buildSettingItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        // Navigate to change password screen
                      },
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () {},
                    ),
                    const Divider(),
                    _buildSettingItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _auth.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                              ),
                            );
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFB45309)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB45309), width: 2),
        ),
      ),
    );
  }

  Widget _buildChildItem(
    String name,
    String grade,
    String initials, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEBD38)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFB45309),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  grade,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          // if (onEdit != null)
          //   IconButton(
          //     icon: const Icon(Icons.edit_outlined, color: Color(0xFFB45309)),
          //     onPressed: onEdit,
          //   ),
          // if (onDelete != null)
          //   IconButton(
          //     icon: const Icon(Icons.delete_outline, color: Colors.red),
          //     onPressed: onDelete,
          //   ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFB45309),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB45309)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Add Child Dialog
class AddChildDialog extends StatefulWidget {
  final String parentId;
  final String parentName;
  final String parentEmail;
  final List<DocumentSnapshot> classes;
  final VoidCallback onChildAdded;

  const AddChildDialog({
    required this.parentId,
    required this.parentName,
    required this.parentEmail,
    required this.classes,
    required this.onChildAdded,
    super.key,
  });

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _registerNoController = TextEditingController();
  String? selectedClassId;
  bool isLoading = false;

  Future<void> _linkStudent() async {
    if (selectedClassId == null || _registerNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class and enter register number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Search for student by register number in selected class
      final studentsSnapshot = await _firestore
          .collection('Classes')
          .doc(selectedClassId)
          .collection('Students')
          .where('registerNo', isEqualTo: _registerNoController.text)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student not found with this register number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final studentDoc = studentsSnapshot.docs.first;
      final studentData = studentDoc.data() as Map<String, dynamic>? ?? {};

      // Check if student already has a parent
      final parentId = studentData['parentid']?.toString();
      if (parentId != null && parentId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This student is already linked to another parent'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update student with parent info
      await studentDoc.reference.update({
        'parentid': widget.parentId,
        'parentName': widget.parentName,
        'parentEmail': widget.parentEmail,
      });

      Navigator.pop(context);
      widget.onChildAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student linked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link Student'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
              ),
              value: selectedClassId,
              items: widget.classes.map((classDoc) {
                final classData = classDoc.data() as Map<String, dynamic>?;
                final className =
                    classData?['name']?.toString() ?? 'Unknown Class';
                final dept = classData?['department']?.toString() ?? '';
                return DropdownMenuItem(
                  value: classDoc.id,
                  child: Text('$className${dept.isNotEmpty ? ' - $dept' : ''}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClassId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _registerNoController,
              decoration: const InputDecoration(
                labelText: 'Student Register Number',
                border: OutlineInputBorder(),
                hintText: 'Enter student register number',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _linkStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB45309),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Link Student'),
        ),
      ],
    );
  }
}

// Edit Child Dialog
class EditChildDialog extends StatefulWidget {
  final Map<String, dynamic> childData;
  final VoidCallback onChildUpdated;

  const EditChildDialog({
    required this.childData,
    required this.onChildUpdated,
    super.key,
  });

  @override
  State<EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<EditChildDialog> {
  @override
  Widget build(BuildContext context) {
    final childName = widget.childData['name']?.toString() ?? 'Unknown';
    final className = widget.childData['className']?.toString() ?? 'No Class';
    final registerNo = widget.childData['registerNo']?.toString() ?? 'N/A';
    final email = widget.childData['email']?.toString() ?? 'N/A';
    final phone = widget.childData['phone']?.toString() ?? 'N/A';

    return AlertDialog(
      title: Text('Student: $childName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class: $className'),
          Text('Register No: $registerNo'),
          Text('Email: $email'),
          Text('Phone: $phone'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
