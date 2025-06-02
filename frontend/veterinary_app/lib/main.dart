import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';
import 'package:veterinary_app/utils/app_colors.dart';
import 'package:veterinary_app/views/video_call_pages/incoming_call_screen.dart';
import 'views/Auth_pages/vet_login_page.dart'; // Make sure this import is correct
import 'views/Auth_pages/vet_register_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Define your primary green color centrally
// Define a secondary accent green for highlights/details

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
        // Use kPrimaryGreen for primary color
        primaryColor: kPrimaryGreen,
        // Define a consistent color scheme using kPrimaryGreen
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryGreen,
          primary: kPrimaryGreen, // Explicitly set primary
          secondary: kAccentGreen, // Explicitly set secondary/accent
          surface:
              Colors.white, // Default surface color for cards, dialogs etc.
          onSurface: Colors.black87, // Text color on surface
          background: Colors.grey.shade50, // Light background for scaffolds
        ),
        useMaterial3: true,
        scaffoldBackgroundColor:
            Colors.grey.shade50, // Consistent light background
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryGreen, // Green app bars
          foregroundColor: Colors.white, // White icons and text on app bars
          elevation: 0, // No shadow for a modern flat look
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen, // Green elevated buttons
            foregroundColor: Colors.white, // White text on elevated buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ), // Rounded corners for buttons
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 4, // Subtle shadow for buttons
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kPrimaryGreen, // Green text buttons
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 6, // Consistent card elevation
          shape: RoundedRectangleBorder(),
          color: Colors.white, // White card background
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: kPrimaryGreen), // Green label text
          prefixIconColor: kAccentGreen, // Accent green prefix icons
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white, // White fill for text fields
        ),
        // Define text themes for consistent typography
        textTheme:
            const TextTheme(
              headlineLarge: TextStyle(color: Colors.black87),
              headlineMedium: TextStyle(color: Colors.black87),
              headlineSmall: TextStyle(color: Colors.black87),
              titleLarge: TextStyle(color: Colors.black87),
              titleMedium: TextStyle(color: Colors.black87),
              titleSmall: TextStyle(color: Colors.black87),
              bodyLarge: TextStyle(color: Colors.black87),
              bodyMedium: TextStyle(color: Colors.black87),
              bodySmall: TextStyle(color: Colors.black54),
              labelLarge: TextStyle(color: Colors.white), // Default for buttons
              labelMedium: TextStyle(color: Colors.black87),
              labelSmall: TextStyle(color: Colors.black54),
            ).apply(
              bodyColor: Colors.black87, // Default text color
              displayColor: Colors.black87,
            ),
      ),
      home:
          const AppWrapper(), // App starts with AppWrapper to manage global state
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
    print(
      '[AppWrapper.initSignalRAndListenGlobally] Attempting to initialize SignalR.',
    );
    if (token.isEmpty) {
      print(
        '[AppWrapper.initSignalRAndListenGlobally] WARNING: Token is empty. Cannot initialize SignalRTCService.',
      );
      return;
    }

    try {
      if (SignalRTCService.connection != null &&
          SignalRTCService.connection!.state == HubConnectionState.connected) {
        print(
          '[AppWrapper.initSignalRAndListenGlobally] SignalRTCService already connected. State: ${SignalRTCService.connection?.state}. Skipping re-initialization.',
        );
      } else {
        print(
          '[AppWrapper.initSignalRAndListenGlobally] SignalRTCService not connected or null. Attempting init...',
        );
        await SignalRTCService.init(token);
        print(
          '[AppWrapper.initSignalRAndListenGlobally] SignalRTCService.init completed successfully.',
        );
      }

      _incomingCallSubscription
          ?.cancel(); // Cancel previous subscription if it exists
      _incomingCallSubscription = SignalRTCService.incomingCallStream.listen(
        (callerId) {
          print(
            '[AppWrapper.initSignalRAndListenGlobally] Incoming call detected from: $callerId',
          );
          _navigateToIncomingCallScreen(callerId);
        },
        onError: (error) {
          print(
            '[AppWrapper.initSignalRAndListenGlobally] Error on incomingCallStream: $error',
          );
        },
        onDone: () {
          print(
            '[AppWrapper.initSignalRAndListenGlobally] incomingCallStream done.',
          );
        },
      );
      print(
        '[AppWrapper.initSignalRAndListenGlobally] Incoming call stream listener set up.',
      );
    } catch (e) {
      print(
        '[AppWrapper.initSignalRAndListenGlobally] ERROR during SignalRTCService initialization or stream setup: $e',
      );
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
        '[AppWrapper._navigateToIncomingCallScreen] Pushing IncomingCallScreen for $callerId.',
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) =>
              IncomingCallScreen(callerId: callerId, callerName: callerId),
          settings: const RouteSettings(name: '/incoming_call_screen'),
        ),
      );
    } else {
      print(
        '[AppWrapper._navigateToIncomingCallScreen] IncomingCallScreen is already active or navigator is null. Not pushing again.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(
      '[AppWrapper.didChangeAppLifecycleState] App lifecycle state changed to: $state',
    );
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
    // MyHomePage is now the main login/welcome screen
    return MyHomePage(
      title: 'Veterinary Services',
      // Pass the global SignalR initialization function down
      onLoginSuccessCallback: initSignalRAndListenGlobally,
    );
  }
}

// MODIFIED: MyHomePage now accepts a callback for when login is successful.
class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.onLoginSuccessCallback,
  });

  final String title;
  final Function(String token)? onLoginSuccessCallback; // New callback property

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(
      context,
    ).textTheme; // Access theme text styles

    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ), // Bold title
        ),
        // backgroundColor and foregroundColor are now handled by AppBarTheme in ThemeData
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Section with Info and Icon
            Container(
              decoration: BoxDecoration(
                color: kPrimaryGreen.withOpacity(
                  0.15,
                ), // Slightly darker background for header
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(
                    30,
                  ), // Rounded bottom corners for a card-like effect
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  // Subtle shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 40,
                horizontal: 30,
              ), // More vertical padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.pets_rounded, // Relevant icon for veterinary app
                    size: 60,
                    color: kPrimaryGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Partner in Animal Healthcare.',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGreen,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Dedicated to empowering veterinary professionals with the tools and resources they need to provide exceptional care.',
                    style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(
                    height: 25,
                  ), // Increased spacing before services
                  // Updated Services List
                  _buildServiceItem(
                    context,
                    Icons.people_alt_rounded, // Icon for clients
                    'Connect with Clients',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceItem(
                    context,
                    Icons.calendar_month_rounded, // Icon for appointments
                    'Appointments & Consultation',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceItem(
                    context,
                    Icons
                        .vaccines_rounded, // Icon for animal documentation/vaccinations
                    'Animal Doc & Vacc',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // Get Started Section with Icon and Sub-text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .handshake_rounded, // More welcoming icon for 'Get Started'
                        size: 35,
                        color: kPrimaryGreen,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Join Our Community',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Login or register to unlock the full potential of our platform. Your journey to enhanced veterinary practice starts here!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Login Button with Icon and Tooltip
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VetLoginPage(
                      onLoginSuccessCallback: onLoginSuccessCallback,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_rounded, color: Colors.white),
              label: const Text('Login Now'),
            ),
            const SizedBox(height: 20),

            // Register Button with Icon and Tooltip
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    kAccentGreen, // Accent green for register button
                elevation: 2, // Slightly less elevation for secondary button
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              icon: const Icon(Icons.how_to_reg_rounded, color: Colors.white),
              label: const Text('Register Here'),
            ),
            const SizedBox(height: 60),

            // Subtle Footer
            Text(
              '© ${DateTime.now().year} Veterinary Services. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to build a consistent service item row
  Widget _buildServiceItem(BuildContext context, IconData icon, String text) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: kAccentGreen, size: 24), // Themed icon for services
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.black87,
            ), // Themed text
          ),
        ),
      ],
    );
  }
}
