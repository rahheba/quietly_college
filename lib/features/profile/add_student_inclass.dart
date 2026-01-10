import 'package:flutter/material.dart';

class CreateClassPage extends StatefulWidget {
  @override
  _CreateClassPageState createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController deviceIdController = TextEditingController();

  List<String> students = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create New Class"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CLASS NAME
            TextField(
              controller: classNameController,
              decoration: InputDecoration(
                labelText: "Class Name",
                hintText: "e.g., 9A Mathematics",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 16),

            /// SUBJECT
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: "Subject",
                hintText: "e.g., Science, English",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 20),

            /// STUDENT ID + ADD
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: deviceIdController,
                    decoration: InputDecoration(
                      labelText: "Student Device ID",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final id = deviceIdController.text.trim();
                    if (id.isNotEmpty && !students.contains(id)) {
                      setState(() {
                        students.add(id);
                        deviceIdController.clear();
                      });
                    }
                  },
                  child: Icon(Icons.add),
                ),
              ],
            ),

            SizedBox(height: 16),

            /// STUDENT LIST
            Text(
              "Students (${students.length})",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: students.isEmpty
                  ? Center(child: Text("No students added"))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.person, color: Colors.green),
                          title: Text(students[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                students.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(height: 30),

            /// CREATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final className = classNameController.text.trim();
                  final subject = subjectController.text.trim();

                  if (className.isEmpty || subject.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  await _createClass({
                    'className': className,
                    'subject': subject,
                    'studentDeviceIds': students,
                  });

                  Navigator.pop(context);
                },
                child: Text("Create Class"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClass(Map<String, dynamic> data) async {
    // Add your Firestore saving code here
  }
}
