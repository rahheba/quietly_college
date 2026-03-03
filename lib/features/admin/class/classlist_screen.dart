import 'package:customtxt_mz/customtxt_mz.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quietly/features/admin/class/addclass_screen.dart';
import 'package:quietly/features/admin/class/classdetail_screen.dart';

class ClassesListScreen extends StatefulWidget {
  final bool? showAppBar;
  const ClassesListScreen({Key? key, this.showAppBar}) : super(key: key);

  @override
  State<ClassesListScreen> createState() => _ClassesListScreenState();
}

class _ClassesListScreenState extends State<ClassesListScreen> {
  Future<void> _showDeleteDialog(BuildContext context, String classId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Class'),
          content: const Text(
            'Are you sure you want to permanently delete this class?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('Classes')
          .doc(classId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.showAppBar ?? false)
          ? AppBar(
              title: const Text('Classes'),
              backgroundColor: Colors.blue,
              elevation: 0,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No classes found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              String className = data['classname'] ?? 'N/A';
              String departmentTitle = data['departmenttitle'] ?? 'N/A';
              String departmentCode = data['departmentcode'] ?? '';
              int status = data['status'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.only(left: 10, right: 10),
                  leading: CircleAvatar(
                    backgroundColor: status == 1 ? Colors.green : Colors.grey,
                    child: Text(
                      departmentCode.isNotEmpty
                          ? departmentCode.substring(0, 1).toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    className,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        departmentTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 1 ? Icons.check_circle : Icons.cancel,
                        color: status == 1 ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 4),

                      InkWell(
                        onTap: () {},
                        child: Icon(Icons.edit, color: Colors.blue),
                      ),
                      SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          _showDeleteDialog(context, document.id);
                        },
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  // Handle tap - navigate to detail screen or show details
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailsScreen(
                          classId: document.id,
                          className: className,
                          departmentName: departmentTitle,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddClassScreen()),
          );
        },

        label: CustomTextMz(text: 'Add Class'),
      ),
    );
  }
}
