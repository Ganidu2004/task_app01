import 'package:flutter/material.dart';

//Texfield Decaration
class AppDecorations {
  static InputDecoration authInputDecoration(
    BuildContext? context, {
    required String labelText,
    required IconData prefixIcon,
  }) {
    final bool isDarkMode = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;

    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
      ),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDarkMode ? Colors.lightBlueAccent : Colors.lightBlue,
      ),
    );
  }
}

// Popup Message Baner
class AppConstants {
  // Global snackbar helper function
  static void showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
