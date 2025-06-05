import 'dart:async'; // Added for StreamSubscription
import 'package:client_app/services/auth_services/token_service.dart'; // Added for TokenService
import 'package:client_app/services/video_call_services/signalr_tc_service.dart'; // Added for SignalRTCService
import 'package:client_app/views/rendezvous_pages/rendezvous_page.dart';
import 'package:client_app/views/vet_pages/veterinary_page.dart';
import 'package:flutter/material.dart';
import 'package:client_app/views/pet_pages/pet_list_page.dart';
import 'package:client_app/views/consultation_pages/consultations_page.dart';
import 'package:client_app/utils/logout_helper.dart';
import 'package:client_app/views/components/home_navbar.dart'; // Assuming this is your custom Navbar
import 'package:client_app/views/video_call_pages/incoming_call_screen.dart'; // Import for IncomingCallScreen

// Import the blue color constants from your centralized app_colors.dart
import 'package:client_app/utils/app_colors.dart';
import 'package:client_app/main.dart';
import 'package:signalr_core/signalr_core.dart'; // Needed for navigatorKey

class HomePage extends StatefulWidget {
  final String username;
  final String token;
  final String initialUserId; // ADDED: To receive the user ID

  const HomePage({
    Key? key,
    required this.username,
    required this.token,
    required this.initialUserId, // ADDED: Required in constructor
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription? _incomingCallSubscription;
  String? _currentUserId; // To store the current user's ID within the state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize current user ID from widget properties
    _currentUserId = widget.initialUserId;
    // Initialize SignalR connection and listeners
    initSignalRAndListenGlobally(widget.token);
  }

  /// Initializes the SignalR connection and sets up listeners for incoming calls.
  /// This function is called when the app starts or resumes.
  void initSignalRAndListenGlobally(String token) async {
    print('[Client HomePage.initSignalRAndListenGlobally] Attempting to initialize SignalR.');
    if (token.isEmpty) {
      print('[Client HomePage.initSignalRAndListenGlobally] WARNING: Token is empty. Cannot initialize SignalRTCService.');
      return;
    }

    try {
      if (SignalRTCService.connection != null &&
          SignalRTCService.connection!.state == HubConnectionState.connected) {
        print('[Client HomePage.initSignalRAndListenGlobally] SignalRTCService already connected. State: ${SignalRTCService.connection?.state}. Skipping re-initialization.');
      } else {
        print('[Client HomePage.initSignalRAndListenGlobally] SignalRTCService not connected or null. Attempting init...');
        await SignalRTCService.init(token);
        print('[Client HomePage.initSignalRAndListenGlobally] SignalRTCService.init completed successfully.');
      }

      // Cancel previous subscription to avoid duplicates if init is called multiple times
      _incomingCallSubscription?.cancel();
      // Listen for incoming call events from SignalR
      _incomingCallSubscription = SignalRTCService.incomingCallStream.listen(
            (callerId) {
          print('[Client HomePage.initSignalRAndListenGlobally] Incoming call detected from: $callerId');
          // Navigate to incoming call screen when a SignalR call is received
          _navigateToIncomingCallScreen(callerId);
        },
        onError: (error) {
          print('[Client HomePage.initSignalRAndListenGlobally] Error on incomingCallStream: $error');
        },
        onDone: () {
          print('[Client HomePage.initSignalRAndListenGlobally] incomingCallStream done.');
        },
      );
      print('[Client HomePage.initSignalRAndListenGlobally] Incoming call stream listener set up.');
    } catch (e) {
      print('[Client HomePage.initSignalRAndListenGlobally] ERROR during SignalRTCService initialization or stream setup: $e');
    }
  }

  /// Navigates to the IncomingCallScreen.
  /// Prevents pushing multiple IncomingCallScreen instances if one is already active.
  void _navigateToIncomingCallScreen(String callerId) {
    bool isIncomingCallScreenActive = false;
    // Check if IncomingCallScreen is already on the navigation stack
    navigatorKey.currentState?.popUntil((route) {
      if (route.settings.name == '/incoming_call_screen') {
        isIncomingCallScreenActive = true;
      }
      return true; // Keep popping until root or this screen found
    });

    if (!isIncomingCallScreenActive && navigatorKey.currentState != null) {
      print('[Client HomePage._navigateToIncomingCallScreen] Pushing IncomingCallScreen for $callerId.');
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerId: callerId,
            callerName: callerId, // Assuming callerId can serve as callerName for now
          ),
          settings: const RouteSettings(name: '/incoming_call_screen'), // Name the route for easy checking
        ),
      );
    } else {
      print('[Client HomePage._navigateToIncomingCallScreen] IncomingCallScreen is already active or navigator is null. Not pushing again.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[Client HomePage.didChangeAppLifecycleState] App lifecycle state changed to: $state');
    // Re-initialize SignalR when the app comes back to the foreground
    if (state == AppLifecycleState.resumed) {
      initSignalRAndListenGlobally(widget.token);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Consider disconnecting SignalR when the app goes into background/inactive state
      // SignalRTCService.disconnect(); // Uncomment if you want to disconnect on pause
    }
  }

  @override
  void dispose() {
    print('[Client HomePage] dispose: Cleaning up SignalR listener and connection.');
    WidgetsBinding.instance.removeObserver(this); // Remove observer to prevent memory leaks
    _incomingCallSubscription?.cancel(); // Cancel any active subscription
    SignalRTCService.disconnect(); // Disconnect SignalR when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      backgroundColor: Colors.grey.shade100, // A very light grey for background
      body: CustomScrollView( // Use CustomScrollView for more flexible scrolling with slivers
        slivers: [
          // --- Welcome Section (SliverToBoxAdapter for fixed height content) ---
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30), // Adjusted padding
              decoration: BoxDecoration(
                color: kPrimaryBlue, // Primary blue background
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)), // More pronounced curve
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15, // Increased blur for softer shadow
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  Text(
                    'Welcome back,', // More engaging greeting
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.username, // Your dynamic username
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What would you like to explore today?', // Clearer call to action
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9), // Slightly less opaque
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Navigation Grid (SliverPadding and SliverGrid for a nice layout) ---
          SliverPadding(
            padding: const EdgeInsets.all(20.0), // Padding around the grid
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns for a compact look
                crossAxisSpacing: 15.0, // Space between columns
                mainAxisSpacing: 15.0, // Space between rows
                childAspectRatio: 1.0, // Make items square
              ),
              delegate: SliverChildListDelegate(
                [
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.search, // Using an icon for search
                    title: 'Find a Vet',
                    color: Colors.lightBlue.shade400, // Unique color for this card
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VetListPage(username: widget.username),
                        ),
                      );
                    },
                  ),
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.history_edu, // Icon for consultations
                    title: 'My Consultations',
                    color: Colors.orange.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultationsPage(
                            username: widget.username,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.pets, // Icon for pets
                    title: 'Manage My Pets',
                    color: Colors.green.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PetListPage()),
                      );
                    },
                  ),
                  _buildGridNavigationCard(
                    context: context,
                    icon: Icons.event_note, // Icon for appointments
                    title: 'My Appointments',
                    color: Colors.purple.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RendezvousPage(username: widget.username),
                        ),
                      );
                    },
                  ),
                  // Add more cards here if needed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New helper function for grid-based navigation cards
  Widget _buildGridNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color, // Color for the icon background
    required VoidCallback onTap,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 8, // More prominent shadow for grid cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.2), // Splash effect matches card color
        highlightColor: color.withOpacity(0.1), // Highlight effect
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              Container(
                padding: const EdgeInsets.all(15), // Padding around the icon
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15), // Light background for the icon
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40, // Larger icon
                  color: color, // Icon color matches card's theme color
                ),
              ),
              const SizedBox(height: 15), // Space between icon and text
              Text(
                title,
                textAlign: TextAlign.center, // Center text
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.black87, // Darker text for readability
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}