import '../../utils/app_colors.dart'; // Correct: Import for kPrimaryBlue, kAccentBlue
import 'package:flutter/material.dart';
// REMOVED: No longer need to import shared_preferences directly here, as TokenService handles it.
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/services/auth_services/token_service.dart'; // Correct: Import TokenService
import 'package:client_app/main.dart'; // Keep this if you need navigatorKey, but not for colors
import 'package:client_app/views/Auth_pages/client_login_page.dart'; // Assuming this is the login page to redirect to
// If MyHomePage is your entry point for non-logged-in users, import that instead
// import 'package:client_app/main.dart' as app_main; // Alias if you need to access main's specific widgets like MyHomePage

class LogoutHelper {
  static Future<void> handleLogout(BuildContext context) async {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners for the dialog
          ),
          elevation: 10, // Add a subtle shadow
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.logout_rounded, // A clear, modern logout icon
                  color: kPrimaryBlue, // Blue icon from app_colors.dart
                  size: 70, // Large icon
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirm Logout',
                  style: textTheme.headlineSmall?.copyWith(
                    color: kPrimaryBlue, // Blue title from app_colors.dart
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to log out of your account?',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryBlue, // From app_colors.dart
                          side: const BorderSide(color: kPrimaryBlue, width: 2), // From app_colors.dart
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue), // From app_colors.dart
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue, // From app_colors.dart
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Logout',
                          style: textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      // CORRECTED: Use TokenService to remove token and user ID
      await TokenService.removeTokenAndUserId();
      print('[LogoutHelper] Token and User ID cleared via TokenService.');

      // CORRECTED: Navigate to the initial welcome/login page (MyHomePage)
      // Ensure navigatorKey is accessible (it's global in main.dart)
      // This will clear the entire navigation stack and push MyHomePage
      if (navigatorKey.currentState != null && navigatorKey.currentState!.mounted) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            // Assuming MyHomePage is the root screen for non-logged-in users.
            // If you have a specific ClientLoginPage you want to go to, use that instead.
            // Based on your main.dart, MyHomePage is the initial entry for non-logged-in users.
            builder: (context) => MyHomePage(
              title: 'Veterinary Services : A Step Towards Digital Pet Healthcare. All rights reserved.',
              // No onLoginSuccessCallback needed here, as it's the entry point.
              // The callback is passed to ClientLoginPage from MyHomePage.
            ),
          ),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      } else {
        print('[LogoutHelper] Error: navigatorKey.currentState is null or not mounted. Cannot navigate.');
      }
    }
  }
}