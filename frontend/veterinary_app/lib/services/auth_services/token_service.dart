import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'user_username'; // NEW: Key for username

  /// Save JWT token, user ID, and username to shared preferences
  static Future<void> saveToken(String token, String userId, String username) async { // MODIFIED: Added username parameter
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username); // NEW: Save the username
    print('[TokenService] Token, User ID, and Username saved.');
  }

  /// Retrieve JWT token from shared preferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('[TokenService] Retrieved token: $token');
    return token;
  }

  /// Retrieve user ID from shared preferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    print('[TokenService] Retrieved User ID: $userId');
    return userId;
  }

  /// NEW: Retrieve username from shared preferences
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    print('[TokenService] Retrieved Username: $username');
    return username;
  }

  /// Remove JWT token, user ID, and username from shared preferences (logout)
  static Future<void> removeTokenAndUserId() async { // MODIFIED: Also remove username
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey); // NEW: Remove the username
    print('[TokenService] JWT, User ID, and Username cleared.');
  }

  /// Check if a user is currently logged in (based on presence of token, user ID, AND username)
  static Future<bool> isLoggedIn() async { // MODIFIED: Check for username too
    final token = await TokenService.getToken();
    final userId = await TokenService.getUserId();
    final username = await TokenService.getUsername(); // NEW: Get username
    return token != null && userId != null && username != null; // NEW: All must be present
  }
}