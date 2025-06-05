import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/services/auth_services/token_service.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';
import 'package:veterinary_app/utils/app_colors.dart';
import 'package:veterinary_app/views/home_page.dart'; // Your actual HomePage (dashboard)
import 'package:veterinary_app/views/video_call_pages/incoming_call_screen.dart';
import 'package:veterinary_app/views/Auth_pages/vet_login_page.dart'; // Your login screen
import 'package:veterinary_app/views/Auth_pages/vet_register_page.dart'; // Your register screen

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
  // If any of these are null, the user is NOT considered fully logged in.
  final bool isLoggedIn = storedToken != null && storedUserId != null && storedUsername != null;
  print('[main.dart] User is logged in: $isLoggedIn');
  print('[main.dart] stored token: $storedToken');
  print('[main.dart] stored id: $storedUserId'); // Changed to id for clarity
  print('[main.dart] stored username: $storedUsername'); // Added username print

  // --- TEMPORARILY COMMENTED OUT: The previous debugging step to force clear ---
  // if (!isLoggedIn && (storedToken != null || storedUserId != null || storedUsername != null)) {
  //   print('[main.dart] Detected incomplete login state. Forcing full token/ID/username clear.');
  //   await TokenService.removeTokenAndUserId();
  //   // Re-fetch after clearing to ensure they are null
  //   storedToken = null;
  //   storedUserId = null;
  //   storedUsername = null;
  //   print('[main.dart] After forced clear: token=$storedToken, userId=$storedUserId, username=$storedUsername');
  // }
  // --- END TEMPORARILY COMMENTED OUT ---


  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    initialToken: storedToken,
    initialUserId: storedUserId, // Pass userId separately
    initialUsername: storedUsername, // Pass username separately
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? initialToken; // Now nullable, as it might be null if not logged in
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
        primaryColor: kPrimaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryGreen,
          primary: kPrimaryGreen,
          secondary: kAccentGreen,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.grey.shade50,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kPrimaryGreen,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: kPrimaryGreen),
          prefixIconColor: kAccentGreen,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryGreen.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black87),
          headlineMedium: TextStyle(color: Colors.black87),
          headlineSmall: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.black87),
          labelSmall: TextStyle(color: Colors.black54),
        ).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
      ),
      home: isLoggedIn
          ? AppWrapper(
        initialToken: initialToken!,
        initialUsername: initialUsername!,
        initialUserId: initialUserId!,
      )
          : MyHomePage(
        title: 'Veterinary Services : A Step Towards Digital Pet Healthcare. All rights reserved.',
        onLoginSuccessCallback: (token) async {
          final String? fetchedUserId = await TokenService.getUserId();
          final String? fetchedUsername = await TokenService.getUsername();

          if (fetchedUserId != null && fetchedUsername != null) {
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
            print('Error: User ID or Username missing after login success. Forcing re-login.');
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const VetLoginPage()),
                  (route) => false,
            );
          }
        },
      ),
      routes: {
        '/login': (context) => const VetLoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  final String initialToken;
  final String initialUsername;
  final String initialUserId;

  const AppWrapper({
    super.key,
    required this.initialToken,
    required this.initialUsername,
    required this.initialUserId,
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
    initSignalRAndListenGlobally(widget.initialToken);
  }

  void initSignalRAndListenGlobally(String token) async {
    print('[AppWrapper.initSignalRAndListenGlobally] Attempting to initialize SignalR.');
    if (token.isEmpty) {
      print('[AppWrapper.initSignalRAndListenGlobally] WARNING: Token is empty. Cannot initialize SignalRTCService.');
      return;
    }

    try {
      if (SignalRTCService.connection != null &&
          SignalRTCService.connection!.state == HubConnectionState.connected) {
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService already connected. State: ${SignalRTCService.connection?.state}. Skipping re-initialization.');
      } else {
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService not connected or null. Attempting init...');
        await SignalRTCService.init(token);
        print('[AppWrapper.initSignalRAndListenGlobally] SignalRTCService.init completed successfully.');
      }

      _incomingCallSubscription?.cancel();
      _incomingCallSubscription = SignalRTCService.incomingCallStream.listen(
            (callerId) {
          print('[AppWrapper.initSignalRAndListenGlobally] Incoming call detected from: $callerId');
          _navigateToIncomingCallScreen(callerId);
        },
        onError: (error) {
          print('[AppWrapper.initSignalRAndListenGlobally] Error on incomingCallStream: $error');
        },
        onDone: () {
          print('[AppWrapper.initSignalRAndListenGlobally] incomingCallStream done.');
        },
      );
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
            callerName: callerId,
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
      // SignalRTCService.disconnect();
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
    return HomePage(
      username: widget.initialUsername,
      token: widget.initialToken,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.onLoginSuccessCallback,
  });

  final String title;
  final Function(String token)? onLoginSuccessCallback;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: kPrimaryGreen.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.pets_rounded,
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
                  const SizedBox(height: 25),
                  _buildServiceItem(
                    context,
                    Icons.people_alt_rounded,
                    'Connect with Clients',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceItem(
                    context,
                    Icons.calendar_month_rounded,
                    'Appointments & Consultation',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceItem(
                    context,
                    Icons.vaccines_rounded,
                    'Animal Doc & Vacc',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake_rounded,
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentGreen,
                elevation: 2,
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

  Widget _buildServiceItem(BuildContext context, IconData icon, String text) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: kAccentGreen, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}