import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Math Class Starting',
      'time': '10 mins ago',
      'read': false,
      'icon': Icons.class_,
    },
    {
      'title': 'Assignment Due Tomorrow',
      'time': '1 hour ago',
      'read': false,
      'icon': Icons.assignment,
    },
    {
      'title': 'Parent-Teacher Meeting',
      'time': '2 hours ago',
      'read': true,
      'icon': Icons.event,
    },
    {
      'title': 'New Study Material Available',
      'time': '5 hours ago',
      'read': true,
      'icon': Icons.book,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: notification['read'] ? 0 : 2,
            color: notification['read'] ? Colors.grey.shade50 : Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notification['read']
                    ? Colors.grey.shade300
                    : Colors.blue,
                child: Icon(
                  notification['icon'],
                  color: notification['read'] ? Colors.grey : Colors.white,
                ),
              ),
              title: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: notification['read']
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(notification['time']),
              trailing: !notification['read']
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
