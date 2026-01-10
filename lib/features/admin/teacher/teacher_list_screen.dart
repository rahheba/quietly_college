import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customtxt_mz/customtxt_mz.dart';
import 'package:flutter/material.dart';
import 'package:quietly/features/admin/teacher/teacher_add_screen.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int? _getStatusFilter() {
    switch (_tabController.index) {
      case 0:
        return null; // All
      case 1:
        return 1; // Active
      case 2:
        return -1; // Deleted
      case 3:
        return 0; // Blocked
      default:
        return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getTeachersStream() {
    final status = _getStatusFilter();
    var query = FirebaseFirestore.instance
        .collection('Users')
        .where('role', isEqualTo: 'teacher')
        .where(
          'namefilter',
          arrayContains: _searchController.text.toLowerCase().isEmpty
              ? null
              : _searchController.text.toLowerCase(),
        );

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  Future<void> _updateTeacherStatus(
    String teacherId,
    int newStatus,
    String actionName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(teacherId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher $actionName successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $actionName teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showActionDialog(
    BuildContext context,
    String teacherId,
    String teacherName,
    int currentStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Teacher'),
        content: Text('Choose an action for $teacherName'),
        actions: [
          if (currentStatus != 1)
            TextButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Activate'),
              onPressed: () {
                Navigator.pop(context);
                _updateTeacherStatus(teacherId, 1, 'activated');
              },
            ),
          if (currentStatus != 0)
            TextButton.icon(
              icon: const Icon(Icons.block, color: Colors.orange),
              label: Text(currentStatus == 0 ? 'Unblock' : 'Block'),
              onPressed: () {
                Navigator.pop(context);
                _updateTeacherStatus(
                  teacherId,
                  0,
                  currentStatus == 0 ? 'unblocked' : 'blocked',
                );
              },
            ),
          if (currentStatus != -1)
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(context, teacherId, teacherName);
              },
            ),
          if (currentStatus == -1)
            TextButton.icon(
              icon: const Icon(Icons.restore, color: Colors.blue),
              label: const Text('Restore'),
              onPressed: () {
                Navigator.pop(context);
                _updateTeacherStatus(teacherId, 1, 'restored');
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String teacherId,
    String teacherName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $teacherName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTeacherStatus(teacherId, -1, 'deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Deleted'),
                Tab(text: 'Blocked'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getTeachersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No teachers found'));
                }

                final docs = snapshot.data!.docs.toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching teachers'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final teacher = docs[index];
                    final data = teacher.data();
                    final teacherId = teacher.id;
                    final name = (data['name'] ?? 'N/A').toString();
                    final email = (data['email'] ?? 'N/A').toString();
                    final status = data['status'] ?? 1;

                    Color statusColor = Colors.green;
                    IconData statusIcon = Icons.check_circle;
                    String statusText = 'Active';

                    if (status == -1) {
                      statusColor = Colors.red;
                      statusIcon = Icons.delete;
                      statusText = 'Deleted';
                    } else if (status == 0) {
                      statusColor = Colors.orange;
                      statusIcon = Icons.block;
                      statusText = 'Blocked';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: statusColor),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // TODO: Navigate to edit screen
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                switch (value) {
                                  case 'activate':
                                    _updateTeacherStatus(
                                      teacherId,
                                      1,
                                      'activated',
                                    );
                                    break;
                                  case 'block':
                                    _updateTeacherStatus(
                                      teacherId,
                                      0,
                                      'blocked',
                                    );
                                    break;
                                  case 'unblock':
                                    _updateTeacherStatus(
                                      teacherId,
                                      1,
                                      'unblocked',
                                    );
                                    break;
                                  case 'delete':
                                    _confirmDelete(context, teacherId, name);
                                    break;
                                  case 'restore':
                                    _updateTeacherStatus(
                                      teacherId,
                                      1,
                                      'restored',
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (context) {
                                List<PopupMenuEntry<String>> items = [];

                                if (status != 1) {
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'activate',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Activate'),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (status == 0) {
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'unblock',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Unblock'),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (status != 0) {
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Block'),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (status == -1) {
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.restore,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Restore'),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return items;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTeacherScreen()),
          );
        },
        label: CustomTextMz(text: 'Add Teacher'),
      ),
    );
  }
}
