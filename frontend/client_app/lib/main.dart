import 'dart:async';

import 'package:client_app/services/auth_services/token_service.dart';
import 'package:client_app/services/video_call_services/signalr_tc_service.dart';
import 'package:client_app/utils/app_colors.dart'; // Correct import for colors
import 'package:client_app/views/Auth_pages/client_login_page.dart';
import 'package:client_app/views/Auth_pages/client_register_page.dart';
import 'package:client_app/views/components/navbar.dart'; // Assuming this is used somewhere else
import 'package:client_app/views/home_page.dart'; // Your actual HomePage (dashboard)
import 'package:client_app/views/video_call_pages/incoming_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_core/signalr_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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

  // Fetch all stored data at app startup
  String? storedToken = await TokenService.getToken();
  String? storedUserId = await TokenService.getUserId();
  String? storedUsername = await TokenService.getUsername(); // Get the username too

  // CRITICAL FIX: isLoggedIn must check for ALL required data for HomePage
  final bool isLoggedIn = storedToken != null && storedUserId != null && storedUsername != null;
  print('[main.dart] User is logged in: $isLoggedIn');
  print('[main.dart] stored token: $storedToken');
  print('[main.dart] stored id: $storedUserId'); // Changed to id for clarity
  print('[main.dart] stored username: $storedUsername'); // Added username print

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    initialToken: storedToken,
    initialUserId: storedUserId, // Pass userId separately
    initialUsername: storedUsername, // Pass username separately
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? initialToken;
  final String? initialUserId; // New: To hold the user ID
  final String? initialUsername; // New: To hold the display username

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.initialToken,
    this.initialUserId, // Initialize
    this.initialUsername, // Initialize
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Veterinary Services : A Step Towards Digital Pet Healthcare. All rights reserved.',
      theme: ThemeData(
        primaryColor: kPrimaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryBlue,
          primary: kPrimaryBlue,
          secondary: kAccentBlue,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.black87),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.black87),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          labelSmall: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimaryBlue,
            side: const BorderSide(color: kPrimaryBlue, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: isLoggedIn
          ? AppWrapper(
        initialToken: initialToken!,
        initialUsername: initialUsername!, // Pass the actual username
        initialUserId: initialUserId!, // Pass the userId
      )
          : MyHomePage(
        title: 'Veterinary Services : A Step Towards Digital Pet Healthcare. All rights reserved.',
        onLoginSuccessCallback: (token) async {
          // This callback is triggered from ClientLoginPage after successful login.
          // We need to fetch userId and username again as they are not passed directly in the callback.
          final String? fetchedUserId = await TokenService.getUserId();
          final String? fetchedUsername = await TokenService.getUsername();

          if (fetchedUserId != null && fetchedUsername != null) {
            // Initialize SignalR and then navigate to AppWrapper
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => AppWrapper(
                  initialToken: token,
                  initialUsername: fetchedUsername,
                  initialUserId: fetchedUserId,
                ),
              ),
            );
          } else {
            // Handle case where user data is missing after login (shouldn't happen if backend is correct)
            print('Error: User ID or Username missing after login success.');
            // Optionally, redirect to login page with an error message
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const ClientLoginPage()),
                  (route) => false,
            );
          }
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  final String initialToken;
  final String initialUsername; // This now holds the display username
  final String initialUserId; // New: To hold the actual user ID

  const AppWrapper({
    super.key,
    required this.initialToken,
    required this.initialUsername,
    required this.initialUserId, // Initialize
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  StreamSubscription? _incomingCallSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize SignalR immediately if user is logged in
    initSignalRAndListenGlobally(widget.initialToken);
  }

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

      _incomingCallSubscription?.cancel();
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
      print('[AppWrapper._navigateToIncomingCallScreen] Pushing IncomingCallScreen for $callerId.');
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerId: callerId,
            callerName: callerId, // Assuming callerId is also the name for now
          ),
          settings: const RouteSettings(name: '/incoming_call_screen'),
        ),
      );
    } else {
      print('[AppWrapper._navigateToIncomingCallScreen] IncomingCallScreen is already active or navigator is null. Not pushing again.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[AppWrapper.didChangeAppLifecycleState] App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      initSignalRAndListenGlobally(widget.initialToken);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // SignalRTCService.disconnect(); // Uncomment if you want to disconnect on pause
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
    // AppWrapper now renders the HomePage if logged in
    return HomePage(
      username: widget.initialUsername, // Pass the display username
      token: widget.initialToken,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title, this.onLoginSuccessCallback});

  final String title;
  final Function(String token)? onLoginSuccessCallback; // New callback property

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: textTheme.titleLarge?.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: kPrimaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting you with trusted veterinarians for compassionate pet care, anytime, anywhere.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to client login page, passing the callback
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientLoginPage(
                            onLoginSuccessCallback: onLoginSuccessCallback, // Pass the callback
                          ),
                        ),
                      );
                      print('Get Started button pressed, navigating to login.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentBlue,
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
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _serviceCard(
                        context,
                        Icons.local_hospital_rounded,
                        'Quick Vet Access',
                        'Connect with licensed veterinarians instantly via video call.',
                        kAccentBlue,
                      ),
                      _serviceCard(
                        context,
                        Icons.calendar_month_rounded,
                        'Online Appointments',
                        'Schedule consultations at your convenience, 24/7.',
                        Colors.orange.shade400,
                      ),
                      _serviceCard(
                        context,
                        Icons.chat_bubble_rounded,
                        'Direct Vet Chat',
                        'Get immediate answers and advice through direct messaging.',
                        Colors.teal.shade400,
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
                      style: textTheme.labelLarge?.copyWith(color: kPrimaryBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Navigate to login page, passing the callback
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientLoginPage(
                            onLoginSuccessCallback: onLoginSuccessCallback, // Pass the callback
                          ),
                        ),
                      );
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

  Widget _serviceCard(
      BuildContext context,
      IconData icon,
      String title,
      String description,
      Color iconColor,
      ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          print('$title service tapped!');
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
              Expanded(
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