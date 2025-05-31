import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import kPrimaryGreen and kAccentGreen from main.dart to ensure theme consistency
import 'package:veterinary_app/main.dart';

import 'app_colors.dart'; // Adjust path if using a separate constants.dart file

class LogoutHelper {
  static Future<void> handleLogout(BuildContext context) async {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext dialogContext) => AlertDialog(
        // Apply themed styling to the AlertDialog
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // More rounded corners
        ),
        backgroundColor: Colors.white, // White background for the dialog
        elevation: 10, // Add subtle elevation
        title: Text(
          'Confirm Logout',
          style: textTheme.titleLarge?.copyWith(
            color: kPrimaryGreen, // Themed title color
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?', // Slightly rephrased for natural flow
          style: textTheme.bodyLarge?.copyWith(color: Colors.black87), // Themed content text
        ),
        actions: [
          // "No" Button (TextButton)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryGreen, // Themed text color
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'No',
              style: textTheme.labelLarge?.copyWith(color: kPrimaryGreen), // Use themed labelLarge
            ),
          ),
          // "OK" Button (ElevatedButton)
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen, // Themed background color
              foregroundColor: Colors.white, // White text color
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              elevation: 4, // Subtle shadow
            ),
            child: Text(
              'Yes, Logout', // More explicit text
              style: textTheme.labelLarge, // Use themed labelLarge
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');
      // Navigate to the root route and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}