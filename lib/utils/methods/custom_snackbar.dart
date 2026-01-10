import 'package:flutter/material.dart';

enum SnackStatus { success, error, warning, info }

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  SnackStatus status = SnackStatus.info,
  Duration duration = const Duration(seconds: 2),
}) {
  Color backgroundColor;
  IconData icon;

  switch (status) {
    case SnackStatus.success:
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
      break;
    case SnackStatus.error:
      backgroundColor = Colors.red;
      icon = Icons.error;
      break;
    case SnackStatus.warning:
      backgroundColor = Colors.orange;
      icon = Icons.warning;
      break;
    default:
      backgroundColor = Colors.blue;
      icon = Icons.info;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
