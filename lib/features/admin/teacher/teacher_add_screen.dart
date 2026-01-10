import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({Key? key}) : super(key: key);

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _uidController = TextEditingController();
  final _employeeIdController = TextEditingController();

  bool _isPasswordVisible = false;

  String? _selectedDepartmentId;
  List<Map<String, dynamic>> departments = [];
  bool _isLoadingDepartments = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      setState(() {
        _isLoadingDepartments = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Department')
          .get();

      final List<Map<String, dynamic>> fetchedDepartments = snapshot.docs.map((
        doc,
      ) {
        return {
          'id': doc.id,
          'code': doc['code'] ?? '',
          'title': doc['title'] ?? '',
        };
      }).toList();

      setState(() {
        departments = fetchedDepartments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDepartments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _teacherNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _uidController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get the selected department details
        final selectedDepartment = departments.firstWhere(
          (dept) => dept['id'] == _selectedDepartmentId,
        );
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .then((value) {
              FirebaseFirestore.instance
                  .collection('Users')
                  .doc(value.user?.uid)
                  .set({
                    'name': _teacherNameController.text,
                    "namefilter": [
                      for (
                        int i = 1;
                        i <= _teacherNameController.text.length;
                        i++
                      )
                        _teacherNameController.text
                            .substring(0, i)
                            .toLowerCase(),
                    ],
                    'email': _emailController.text,
                    'password': _passwordController.text,
                    'uid': value.user?.uid,
                    'departmentid': selectedDepartment['id'],
                    'departmentcode': selectedDepartment['code'],
                    'departmenttitle': selectedDepartment['title'],
                    'status': 1,
                    "role": "teacher",
                    'createdAt': FieldValue.serverTimestamp(),
                  });
            })
            .then((value) {
              if (mounted) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);

                // Clear form
                _teacherNameController.clear();
                _emailController.clear();
                _passwordController.clear();
                _uidController.clear();
                _employeeIdController.clear();
                setState(() {
                  _selectedDepartmentId = null;
                });
              }
            });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding teacher: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
        backgroundColor: const Color.fromARGB(255, 75, 51, 31),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teacher Name Field
              TextFormField(
                controller: _teacherNameController,
                decoration: InputDecoration(
                  labelText: 'Teacher Name',
                  hintText: 'Enter teacher name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 75, 51, 31),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter teacher name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 75, 51, 31),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 75, 51, 31),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
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

              const SizedBox(height: 20),

              // Employee ID Field
              TextFormField(
                controller: _employeeIdController,
                decoration: InputDecoration(
                  labelText: 'Employee ID',
                  hintText: 'Enter employee ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 75, 51, 31),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter employee ID';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Department Dropdown
              _isLoadingDepartments
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 75, 51, 31),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        hintText: 'Select department',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 75, 51, 31),
                            width: 2,
                          ),
                        ),
                        // prefixIcon: const Icon(Icons.business),
                      ),
                      items: departments.map((department) {
                        return DropdownMenuItem<String>(
                          value: department['id'],
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Text(
                              '${department['title']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),

              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 75, 51, 31),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Add Teacher',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
