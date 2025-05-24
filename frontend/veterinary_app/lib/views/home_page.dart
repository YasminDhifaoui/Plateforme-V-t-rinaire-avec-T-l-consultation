import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/utils/logout_helper.dart';
import 'package:veterinary_app/views/consultation_pages/consultation_page.dart';
import 'package:veterinary_app/views/product_pages/products_list_page.dart';
import 'package:veterinary_app/views/rendezvous_pages/rendezvous_list_page.dart';
import 'package:veterinary_app/views/animal_pages/animals_list_page.dart';
import 'package:veterinary_app/views/client_pages/clients_list_page.dart';
import 'package:veterinary_app/views/vaccination_pages/vaccination_list_page.dart';
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart';
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart';
import 'package:veterinary_app/services/client_services/client_service.dart';
import 'package:veterinary_app/services/consultation_services/consultation_service.dart';
import 'package:veterinary_app/services/product_services/product_service.dart';
import 'package:veterinary_app/services/vaccination_services/vaccination_service.dart';
import 'package:veterinary_app/services/video_call_services/signalr_tc_service.dart';
import 'package:veterinary_app/views/video_call_pages/incoming_call_screen.dart';
import 'package:veterinary_app/views/video_call_pages/video_call_screen.dart';

import 'components/home_navbar.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String token;

  const HomePage({super.key, required this.username, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription? _incomingCallSubscription;

  // Keep services and counts, as they are not UI elements directly
  final AnimalsVetService _animalsVetService = AnimalsVetService();
  final RendezVousService _rendezVousService = RendezVousService();
  final ClientService _clientService = ClientService();
  final ConsultationService _consultationService = ConsultationService();
  final VaccinationService _vaccinationService = VaccinationService();
  final ProductService _productService = ProductService();

  int animalCount = 0;
  int rendezvousCount = 0;
  int clientsCount = 0;
  int consultationsCount = 0;
  int vaccinationsCount = 0;
  int productCount = 0;

  @override
  void initState() {
    super.initState();
    print('[HomePage] initState called. Username: ${widget.username}, Token length: ${widget.token.length}');
    WidgetsBinding.instance.addObserver(this);
    _initSignalRAndListen(); // Keep this as it seems to be working for calls
    _fetchDataCounts(); // Keep initial data fetch
  }

  Future<void> _initSignalRAndListen() async {
    print('[HomePage._initSignalRAndListen] Attempting to initialize SignalR.');
    if (widget.token.isEmpty) {
      print('[HomePage._initSignalRAndListen] WARNING: Token is empty. Cannot initialize SignalRTCService.');
      return;
    }

    try {
      if (SignalRTCService.connection != null && SignalRTCService.connection!.state == HubConnectionState.connected) {
        print('[HomePage._initSignalRAndListen] SignalRTCService already connected. State: ${SignalRTCService.connection?.state}. Skipping re-initialization.');
      } else {
        print('[HomePage._initSignalRAndListen] SignalRTCService not connected or null. Attempting init...');
        await SignalRTCService.init(widget.token);
        print('[HomePage._initSignalRAndListen] SignalRTCService.init completed successfully.');
      }

      if (_incomingCallSubscription != null) {
        await _incomingCallSubscription!.cancel();
        print('[HomePage._initSignalRAndListen] Previous _incomingCallSubscription cancelled.');
      }

      _incomingCallSubscription = SignalRTCService.incomingCallStream.listen((callerId) {
        print('[HomePage._initSignalRAndListen] Incoming call detected from: $callerId');
        _navigateToIncomingCallScreen(callerId);
      }, onError: (error) {
        print('[HomePage._initSignalRAndListen] Error on incomingCallStream: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error on call stream: $error')),
        );
      }, onDone: () {
        print('[HomePage._initSignalRAndListen] incomingCallStream done.');
      });
      print('[HomePage._initSignalRAndListen] Incoming call stream listener set up.');

    } catch (e) {
      print('[HomePage._initSignalRAndListen] ERROR during SignalRTCService initialization or stream setup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to call service: $e')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[HomePage.didChangeAppLifecycleState] App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('[HomePage.didChangeAppLifecycleState] App resumed. Re-initializing SignalR listener.');
      _initSignalRAndListen();
    }
  }

  void _navigateToIncomingCallScreen(String callerId) {
    bool isIncomingCallScreenActive = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/incoming_call_screen') {
        isIncomingCallScreenActive = true;
      }
      return true;
    });

    if (!isIncomingCallScreenActive) {
      print('[HomePage._navigateToIncomingCallScreen] Pushing ORIGINAL IncomingCallScreen for $callerId.');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(
            callerId: callerId,
            callerName: callerId,
          ),
          settings: const RouteSettings(name: '/incoming_call_screen'),
        ),
      );
    } else {
      print('[HomePage._navigateToIncomingCallScreen] IncomingCallScreen is already active. Not pushing again.');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDataCounts();
  }

  Future<void> _fetchDataCounts() async {
    setState(() {
      Future.wait([
        _fetchAnimalCount(),
        _fetchRendezvousCount(),
        _fetchClientsCount(),
        _fetchConsultationsCount(),
        _fetchVaccinationsCount(),
        _fetchProductCount(),
      ]);
    });
  }

  Future<void> _fetchAnimalCount() async {
    try {
      final animals = await _animalsVetService.getAnimalsList(widget.token);
      if (mounted) {
        setState(() {
          animalCount = animals.length;
          print('HomePage: animalCount updated to $animalCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching animal count: $e');
      if (mounted) {
        setState(() {
          animalCount = 0;
        });
      }
    }
  }

  Future<void> _fetchRendezvousCount() async {
    try {
      final rendezvous = await _rendezVousService.getRendezVousList(
        widget.token,
      );
      if (mounted) {
        setState(() {
          rendezvousCount = rendezvous.length;
          print('HomePage: rendezvousCount updated to $rendezvousCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching rendezvous count: $e');
      if (mounted) {
        setState(() {
          rendezvousCount = 0;
        });
      }
    }
  }

  Future<void> _fetchClientsCount() async {
    try {
      final clients = await _clientService.getAllClients(widget.token);
      if (mounted) {
        setState(() {
          clientsCount = clients.length;
          print('HomePage: clientsCount updated to $clientsCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching clients count: $e');
      if (mounted) {
        setState(() {
          clientsCount = 0;
        });
      }
    }
  }

  Future<void> _fetchConsultationsCount() async {
    try {
      final consultations = await ConsultationService.fetchConsultations(
        widget.token,
      );
      if (mounted) {
        setState(() {
          consultationsCount = consultations.length;
          print('HomePage: consultationsCount updated to $consultationsCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching consultations count: $e');
      if (mounted) {
        setState(() {
          consultationsCount = 0;
        });
      }
    }
  }

  Future<void> _fetchVaccinationsCount() async {
    try {
      final vaccinations = await _vaccinationService.getAllVaccinations(
        widget.token,
      );
      if (mounted) {
        setState(() {
          vaccinationsCount = vaccinations.length;
          print('HomePage: vaccinationsCount updated to $vaccinationsCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching vaccinations count: $e');
      if (mounted) {
        setState(() {
          vaccinationsCount = 0;
        });
      }
    }
  }

  Future<void> _fetchProductCount() async {
    try {
      final products = await _productService.getAllProducts(widget.token);
      if (mounted) {
        setState(() {
          productCount = products.length;
          print('HomePage: productCount updated to $productCount');
        });
      }
    } catch (e) {
      debugPrint('Error fetching products count: $e');
      if (mounted) {
        setState(() {
          productCount = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    print('[HomePage] dispose: Cleaning up SignalR listener and connection.');
    WidgetsBinding.instance.removeObserver(this);
    _incomingCallSubscription?.cancel();
    SignalRTCService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[HomePage.build] Building HomePage UI. Current animalCount: $animalCount'); // Added log
    // final cardTextStyle = TextStyle(...); // You can keep these, they won't cause issues here
    // final cardIconColor = Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home - Dr. ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.handleLogout(context),
          ),

        ],
      ),
      body: Center( // Start with a drastically simplified body
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home Page is Rendering!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            SizedBox(height: 20),
            Text(
              'If you see this, the green screen is gone!',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 20),
            // You can optionally add a button to manually trigger data fetch
            // ElevatedButton(
            //   onPressed: _fetchDataCounts,
            //   child: Text('Refresh Data'),
            // ),
            // Text('Animal Count: $animalCount'), // Show count if data fetch works
          ],
        ),
      ),
      bottomNavigationBar: HomeNavbar(username: widget.username),
    );
  }

  // Keep _buildHomeCard and ColorExtension, they are not used by the simplified body
  Widget _buildHomeCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required TextStyle textStyle,
        required Color iconColor,
        int? count,
        Color? cardColor,
      }) {
    return Card(
      elevation: 6,
      color: cardColor ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 8),
              Text(label, style: textStyle, textAlign: TextAlign.center),
              if (count != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor.darken(0.4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}