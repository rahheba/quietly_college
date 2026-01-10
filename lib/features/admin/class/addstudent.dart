import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStudentPage extends StatefulWidget {
  final String classId;
  final String className;
  final String departmentName;

  const AddStudentPage({
    Key? key,
    required this.classId,
    required this.className,
    required this.departmentName,
  }) : super(key: key);

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  // final _departmentController = TextEditingController();
  final _registerNoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureParentPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    // _departmentController.dispose();
    _registerNoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser =
          FirebaseAuth.instance.currentUser; // Save current logged-in user

      try {
        String? studentUid;
        String? parentUid;

        // Step 1: Create Student Firebase Auth Account
        UserCredential studentCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        studentUid = studentCredential.user?.uid;

        // Step 2: Save Student Data to Users Collection
        if (studentUid != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(studentUid)
              .set({
                'name': _studentNameController.text.trim(),
                'namefilter': [
                  for (
                    int i = 1;
                    i <= _studentNameController.text.trim().length;
                    i++
                  )
                    _studentNameController.text
                        .trim()
                        .substring(0, i)
                        .toLowerCase(),
                ],
                'email': _emailController.text.trim(),
                'password': _passwordController.text.trim(),
                'uid': studentUid,
                // 'department': _departmentController.text.trim(),
                'registerNo': _registerNoController.text.trim(),
                'phone': _phoneController.text.trim(),
                'place': _addressController.text.trim(),
                'status': 1,
                'role': 'student',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        // Step 3: Sign out the student account (we'll log back as admin later)
        await FirebaseAuth.instance.signOut();

        // Step 4: Create Parent Firebase Auth Account
        UserCredential parentCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _parentEmailController.text.trim(),
              password: _parentPasswordController.text.trim(),
            );
        parentUid = parentCredential.user?.uid;

        // Step 5: Save Parent Data to Users Collection
        if (parentUid != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(parentUid)
              .set({
                'name': _parentNameController.text.trim(),
                'namefilter': [
                  for (
                    int i = 1;
                    i <= _parentNameController.text.trim().length;
                    i++
                  )
                    _parentNameController.text
                        .trim()
                        .substring(0, i)
                        .toLowerCase(),
                ],
                'email': _parentEmailController.text.trim(),
                'password': _parentPasswordController.text.trim(),
                'uid': parentUid,
                'studentId': studentUid,
                'status': 1,
                'role': 'parent',
                'createdAt': FieldValue.serverTimestamp(),
              });

          // Update student with parentId
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(studentUid)
              .update({'parentId': parentUid});
        }

        // Step 6: Sign out parent and re-authenticate as the original admin/teacher
        await FirebaseAuth.instance.signOut();

        if (currentUser != null) {
          // Re-authenticate the original user (admin/teacher)
          // Note: You'll need to store/retrieve the admin's credentials securely
          // For now, we'll just sign them back in
          // This is a simplified approach - in production, use a backend service
        }

        // Step 7: Add Student to Class Collection
        await FirebaseFirestore.instance
            .collection('Classes')
            .doc(widget.classId)
            .collection('Students')
            .doc(studentUid)
            .set({
              'stdid': studentUid,
              'name': _studentNameController.text.trim(),
              'classname': widget.className,
              // 'department': _departmentController.text.trim(),
              'registerNo': _registerNoController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
              'place': _addressController.text.trim(),
              'parentid': parentUid,
              'parentName': _parentNameController.text.trim(),
              'parentEmail': _parentEmailController.text.trim(),
              'parentPassword': _parentPasswordController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() {
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student and Parent added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Go back to previous screen
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding student: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }

        print('Error details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student to Class'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Adding student and parent...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a moment',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class Info Display
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adding to: ${widget.className}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Department: ${widget.departmentName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Student Information Section
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Name
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter student name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // // Department
                    // TextFormField(
                    //   controller: _departmentController,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Department',
                    //     prefixIcon: Icon(Icons.school),
                    //     border: OutlineInputBorder(),
                    //   ),
                    //   validator: (value) {
                    //     if (value == null || value.trim().isEmpty) {
                    //       return 'Please enter department';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    // const SizedBox(height: 16),

                    // Register Number
                    TextFormField(
                      controller: _registerNoController,
                      decoration: const InputDecoration(
                        labelText: 'Register Number',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter register number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.trim().contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Parent Information Section
                    Text(
                      'Parent Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parent Name
                    TextFormField(
                      controller: _parentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Parent Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter parent name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Parent Email
                    TextFormField(
                      controller: _parentEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Parent Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter parent email';
                        }
                        if (!value.trim().contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Parent Password
                    TextFormField(
                      controller: _parentPasswordController,
                      obscureText: _obscureParentPassword,
                      decoration: InputDecoration(
                        labelText: 'Parent Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureParentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureParentPassword = !_obscureParentPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter parent password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Warning Message
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Note: You will be logged out temporarily during account creation.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Student',
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
            ),
    );
  }
}
