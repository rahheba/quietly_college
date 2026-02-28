import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _brown = Color.fromARGB(255, 145, 87, 1);
  static const Color _lightBrown = Color(0xFFF5ECD7);

  // ------------------------------------------------------------------
  // Firestore stream – sorted newest-first
  // ------------------------------------------------------------------
  Stream<QuerySnapshot> _notificationsStream() {
    return FirebaseFirestore.instance
        .collection('Notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ------------------------------------------------------------------
  // Mark a single notification as read
  // ------------------------------------------------------------------
  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(docId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // ------------------------------------------------------------------
  // Mark ALL notifications as read
  // ------------------------------------------------------------------
  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['read'] == false) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }

  // ------------------------------------------------------------------
  // Format Firestore Timestamp → human-readable string
  // ------------------------------------------------------------------
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  // ------------------------------------------------------------------
  // Icon per notification title keyword
  // ------------------------------------------------------------------
  IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('assign')) return Icons.assignment_outlined;
    if (t.contains('class') || t.contains('lesson'))
      return Icons.class_outlined;
    if (t.contains('meet') || t.contains('event')) return Icons.event_outlined;
    if (t.contains('attend')) return Icons.how_to_reg_outlined;
    if (t.contains('exam') || t.contains('test')) return Icons.quiz_outlined;
    if (t.contains('result') || t.contains('grade'))
      return Icons.grade_outlined;
    if (t.contains('holiday')) return Icons.beach_access_outlined;
    return Icons.notifications_outlined;
  }

  // ------------------------------------------------------------------
  // Show full notification detail as a bottom sheet
  // ------------------------------------------------------------------
  void _showDetail(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    // Mark read on open
    if (data['read'] == false) _markAsRead(docId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _brown,
                    child: Icon(
                      _iconForTitle(data['title'] ?? ''),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Notification',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lightBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['message'] ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(
                Icons.person_outline,
                'From',
                data['senderName'] ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _detailRow(
                Icons.access_time_outlined,
                'Time',
                _formatTime(data['timestamp']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _brown),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        // Count unread
        final unreadCount = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['read'] == false;
        }).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F4EE),
          appBar: AppBar(
            title: const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4),
            ),
            backgroundColor: _brown,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () => _markAllAsRead(docs),
                  icon: const Icon(
                    Icons.done_all,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'All read',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildBody(snapshot, docs, unreadCount),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<QuerySnapshot> snapshot,
    List<QueryDocumentSnapshot> docs,
    int unreadCount,
  ) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }

    // Error
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load notifications\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: Colors.brown.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see messages from your teachers here.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Unread badge header
        if (unreadCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _brown.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _brown.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  color: _brown,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: _brown,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] == true;

              return _NotificationTile(
                docId: doc.id,
                data: data,
                isRead: isRead,
                formattedTime: _formatTime(data['timestamp']),
                icon: _iconForTitle(data['title'] ?? ''),
                onTap: () => _showDetail(context, doc.id, data),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Tile Widget
// ---------------------------------------------------------------------------
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.docId,
    required this.data,
    required this.isRead,
    required this.formattedTime,
    required this.icon,
    required this.onTap,
  });

  final String docId;
  final Map<String, dynamic> data;
  final bool isRead;
  final String formattedTime;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _brown = Color.fromARGB(255, 145, 87, 1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : _brown.withOpacity(0.35),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: _brown.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.grey.shade100
                      : _brown.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isRead ? Colors.grey.shade400 : _brown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14.5,
                              color: isRead
                                  ? Colors.black87
                                  : Colors.brown.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _brown,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message preview
                    Text(
                      data['message'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Footer: sender + time
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['senderName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: isRead ? Colors.grey.shade400 : _brown,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
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
}
