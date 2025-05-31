import 'dart:async';

import 'package:client_app/services/video_call_services/signalr_tc_service.dart';
import 'package:client_app/views/Auth_pages/client_login_page.dart';
import 'package:client_app/views/Auth_pages/client_register_page.dart';
import 'package:client_app/views/components/navbar.dart';
import 'package:client_app/views/video_call_pages/incoming_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_core/signalr_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Define your primary blue color centrally
const Color kPrimaryBlue = Color(0xFF1976D2); // A strong, professional blue
const Color kAccentBlue = Color(0xFF64B5F6); // A lighter, friendly blue
const Color kLightGreyBackground = Color(0xFFF5F7FA); // A very light grey for subtle backgrounds

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // handle notification tap
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Veterinary Services',
      theme: ThemeData(
        // Use kPrimaryBlue for primary theme color
        primaryColor: kPrimaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryBlue,
          primary: kPrimaryBlue,
          secondary: kAccentBlue, // Use accent blue for secondary elements
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Ensures consistent white background
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryBlue, // Blue app bar
          foregroundColor: Colors.white, // White icons/text on app bar
          elevation: 0, // No shadow for a modern flat look
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.black87),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.black87),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87), // Used for section titles
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), // For buttons
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          labelSmall: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue, // Blue button background
            foregroundColor: Colors.white, // White text on buttons
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryBlue, // Blue text/border for outlined buttons
            side: const BorderSide(color: kPrimaryBlue, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const AppWrapper(),
    );
  }
}

// NEW WIDGET: AppWrapper to handle global SignalR logic and app lifecycle
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  StreamSubscription? _incomingCallSubscription;

  // This method will be called from the 2FA verification page after a successful login
  void initSignalRAndListenGlobally(String token) async {
    print('[AppWrapper.initSignalRAndListenGlobally] Attempting to initialize SignalR.');
    if (token.isEmpty) {
      print('[AppWrapper.initSignalRAndListenGlobally] WARNING: Token is empty. Cannot initialize SignalRTCService.');
      return;
    }

    try {
      if (SignalRTCService.connection != null && SignalRTCService.connection!.state == HubConnectionState.connected) {
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService already connected. State: ${SignalRTCService.connection?.state}. Skipping re-initialization.');
      } else {
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService not connected or null. Attempting init...');
        await SignalRTCService.init(token);
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService.init completed successfully.');
      }

      _incomingCallSubscription?.cancel(); // Cancel previous subscription if it exists
      _incomingCallSubscription = SignalRTCService.incomingCallStream.listen((callerId) {
        print('[AppWrapper.initSignalRAndListenGlobally] Incoming call detected from: $callerId');
        _navigateToIncomingCallScreen(callerId);
      }, onError: (error) {
        print('[AppWrapper.initSignalRAndListenGlobally] Error on incomingCallStream: $error');
      }, onDone: () {
        print('[AppWrapper.initSignalRAndListenGlobally] incomingCallStream done.');
      });
      print('[AppWrapper.initSignalRAndListenGlobally] Incoming call stream listener set up.');

    } catch (e) {
      print('[AppWrapper.initSignalRAndListenGlobally] ERROR during SignalRTCService initialization or stream setup: $e');
    }
  }
  void _navigateToIncomingCallScreen(String callerId) {
    bool isIncomingCallScreenActive = false;
    navigatorKey.currentState?.popUntil((route) {
      if (route.settings.name == '/incoming_call_screen') {
        isIncomingCallScreenActive = true;
      }
      return true;
    });

    if (!isIncomingCallScreenActive && navigatorKey.currentState != null) {
      print(
          '[AppWrapper._navigateToIncomingCallScreen] Pushing IncomingCallScreen for $callerId.');
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerId: callerId,
            callerName: callerId,
          ),
          settings: const RouteSettings(name: '/incoming_call_screen'),
        ),
      );
    } else {
      print(
          '[AppWrapper._navigateToIncomingCallScreen] IncomingCallScreen is already active or navigator is null. Not pushing again.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[AppWrapper.didChangeAppLifecycleState] App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      // You might re-initialize SignalR here if needed, depending on token management
    }
  }

  @override
  void dispose() {
    print('[AppWrapper] dispose: Cleaning up SignalR listener and connection.');
    WidgetsBinding.instance.removeObserver(this);
    _incomingCallSubscription?.cancel();
    SignalRTCService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For now, let's keep MyHomePage as the initial home.
    // In a real app, you'd likely check auth status here and navigate to login/home.
    return MyHomePage(
      title: '',
      onLoginSuccessCallback: initSignalRAndListenGlobally,
    );
  }
}

// MODIFIED: MyHomePage now accepts a callback for when login is successful.
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title, this.onLoginSuccessCallback});

  final String title;
  final Function(String token)? onLoginSuccessCallback; // New callback property

  @override
  Widget build(BuildContext context) {
    // Get text theme for consistent styling
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // The Navbar here is an example. You might want a custom AppBar or no AppBar on a splash/welcome screen.
      // For a "main page" after login, a proper Navbar (from your components/navbar.dart) would fit.
      // If this is a landing page before login, a custom clean AppBar or no AppBar might be better.
      appBar: AppBar(
        title: Text(title, style: textTheme.titleLarge?.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        // You can add leading/trailing icons if needed
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Hero Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              decoration: const BoxDecoration(
                color: kPrimaryBlue,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Pet\'s Health, Our Priority',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      // fontSize: 32, // Override if needed
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting you with trusted veterinarians for compassionate pet care, anytime, anywhere.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      // fontSize: 16, // Override if needed
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to client login page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientLoginPage()));
                      print('Get Started button pressed, navigating to login.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue, // Use accent blue for the button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Get Started',
                      style: textTheme.labelLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            // --- Services Section ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Core Services',
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2, // Two items per row
                    shrinkWrap: true, // Important for Grids in a SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disable gridview's own scrolling
                    mainAxisSpacing: 16, // Spacing between rows
                    crossAxisSpacing: 16, // Spacing between columns
                    childAspectRatio: 0.9, // Adjust aspect ratio for card height
                    children: [
                      _serviceCard(
                        context,
                        Icons.local_hospital_rounded, // Using Flutter Icons, replace with your assets
                        'Quick Vet Access',
                        'Connect with licensed veterinarians instantly via video call.',
                        kAccentBlue,
                      ),
                      _serviceCard(
                        context,
                        Icons.calendar_month_rounded,
                        'Online Appointments',
                        'Schedule consultations at your convenience, 24/7.',
                        Colors.orange.shade400, // A warm accent for variety
                      ),
                      _serviceCard(
                        context,
                        Icons.chat_bubble_rounded, // New icon for direct chat
                        'Direct Vet Chat',
                        'Get immediate answers and advice through direct messaging.',
                        Colors.teal.shade400, // A suitable color for chat/communication
                      ),
                      _serviceCard(
                        context,
                        Icons.medical_services_rounded,
                        'Specialized Care',
                        'Access a network of specialists for unique pet needs.',
                        kPrimaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Call to Action / Footer Section (Optional, add more content as needed) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              color: kLightGreyBackground,
              child: Column(
                children: [
                  Text(
                    'Ready to give your pet the best care?',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to registration page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientRegisterPage()));
                      print('Register now button pressed, navigating to register.');
                    },
                    child: Text(
                      'Register Now',
                      style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue), // LabelLarge usually white, override for outlined button
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Navigate to login page
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientLoginPage()));
                      print('Already have an account? Login button pressed, navigating to login.');
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: textTheme.bodyMedium?.copyWith(color: kPrimaryBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a visually appealing service card
  Widget _serviceCard(
      BuildContext context,
      IconData icon, // Using IconData for built-in Flutter icons
      String title,
      String description,
      Color iconColor,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero, // Card handles its own margin now
      child: InkWell(
        onTap: () {
          print('$title service tapped!');
          // Implement navigation or action for this service
          // For now, these are just print statements.
          // Later, you might navigate to a service-specific screen.
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: iconColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded( // Use Expanded to ensure description fits without overflow
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}