import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({Key? key}) : super(key: key);

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _classCodeController = TextEditingController();

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
    _classNameController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get the selected department details
        final selectedDepartment = departments.firstWhere(
          (dept) => dept['id'] == _selectedDepartmentId,
        );
        final docRef = await FirebaseFirestore.instance
            .collection('Classes')
            .add({
              'classname': _classNameController.text,
              'departmentid': selectedDepartment['id'],
              'departmentcode': selectedDepartment['code'],
              'departmenttitle': selectedDepartment['title'],
              'status': 1,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Now update the same document with its own ID
        await docRef.update({'id': docRef.id});

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);

          // Clear form
          _classNameController.clear();
          _classCodeController.clear();
          setState(() {
            _selectedDepartmentId = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding class: $e'),
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
        title: const Text('Add Class'),
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
              // Class Title/Name Field
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(
                  labelText: 'Class Title',
                  hintText: 'Enter class title',
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
                  prefixIcon: const Icon(Icons.class_),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class title';
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
                      initialValue: _selectedDepartmentId,
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
                  'Add Class',
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
