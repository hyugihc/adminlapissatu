import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

class SnackbarHelper {
  SnackbarHelper._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    final Color backgroundColor;
    final IconData iconData;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = Colors.green[600]!;
        iconData = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red[600]!;
        iconData = Icons.error_outline;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blue[600]!;
        iconData = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(
        children: [
          Icon(iconData, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
