import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';
import 'package:veterinary_app/views/video_call_pages/incoming_call_screen.dart';
import 'views/Auth_pages/vet_login_page.dart'; // Make sure this import is correct
import 'views/Auth_pages/vet_register_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Define your primary green color centrally
const Color kPrimaryGreen = Color(0xFF00A86B);

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
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Crucial for white backgrounds
      ),
      home: const AppWrapper(), // App starts with AppWrapper to manage global state
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
  const MyHomePage({super.key, required this.title, this.onLoginSuccessCallback});

  final String title;
  final Function(String token)? onLoginSuccessCallback; // New callback property

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: kPrimaryGreen.withOpacity(0.05),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Veterinarians!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGreen,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Our platform is built specifically for veterinary professionals. Manage appointments, access resources, and collaborate with your peers to deliver the best care to animals.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pass the callback to Login Page
                    builder: (context) => VetLoginPage(onLoginSuccessCallback: onLoginSuccessCallback),
                  ),
                );
              },
              child: const Text('Login', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Register', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}