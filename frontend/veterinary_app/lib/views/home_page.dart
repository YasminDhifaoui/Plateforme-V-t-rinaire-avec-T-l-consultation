import 'package:flutter/material.dart';
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
import 'components/home_navbar.dart';

// CORRECTED: Import kPrimaryGreen and kAccentGreen from your new centralized file
import 'package:veterinary_app/utils/app_colors.dart'; // <--- KEEP THIS LINE

// REMOVE THIS LINE: This was the source of the duplicate import error.
// import 'package:veterinary_app/main.dart'; // <-- DELETE THIS LINE

class HomePage extends StatefulWidget {
  final String username;
  final String token;

  const HomePage({super.key, required this.username, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  bool _isFetchingCounts = false; // To show loading state for counts

  @override
  void initState() {
    super.initState();
    _fetchDataCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDataCounts();
  }

  Future<void> _fetchDataCounts() async {
    if (_isFetchingCounts) return; // Prevent multiple simultaneous fetches

    setState(() {
      _isFetchingCounts = true;
    });

    try {
      await Future.wait([
        _fetchAnimalCount(),
        _fetchRendezvousCount(),
        _fetchClientsCount(),
        _fetchConsultationsCount(),
        _fetchVaccinationsCount(),
        _fetchProductCount(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCounts = false;
        });
      }
    }
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
      final consultations =
      await ConsultationService.fetchConsultations(widget.token);
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
      final vaccinations =
      await _vaccinationService.getAllVaccinations(widget.token);
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
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Define consistent styles based on your theme, providing a default if null
    final cardLabelTextStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.white, // Text color on cards
    ) ??
        const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 16); // Default if titleMedium is null
    final cardCountValueTextStyle = textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white, // Count text color on cards
    ) ??
        const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24); // Default if headlineSmall is null

    return Scaffold(
      backgroundColor:
      Theme.of(context).colorScheme.background, // Use themed background
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.username}!',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen, // Themed welcome text
                ) ??
                    const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 28), // Default if headlineMedium is null
              ),
              const SizedBox(height: 8),
              Text(
                'Quick overview of your clinic data:',
                style: textTheme.bodyLarge?.copyWith(color: Colors.black54) ??
                    const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Expanded(
                // Use Expanded to allow GridView to take available space
                child: _isFetchingCounts
                    ? Center(
                  child: CircularProgressIndicator(
                      color: kPrimaryGreen), // Themed loading indicator
                )
                    : GridView.count(
                  shrinkWrap: true,
                  // Use shrinkWrap because it's inside a Column with Expanded
                  physics: const AlwaysScrollableScrollPhysics(), // Allow scrolling if content overflows
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: [
                    _buildHomeCard(
                      context,
                      icon: Icons.pets_rounded, // Modern icon
                      label: 'Animals',
                      count: animalCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnimalsListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kAccentGreen.withOpacity(0.9), // Themed card color
                      iconColor: Colors.white, // White icon on colored card
                      labelTextStyle:
                      cardLabelTextStyle, // Themed label style
                      countTextStyle:
                      cardCountValueTextStyle, // Themed count style
                    ),
                    _buildHomeCard(
                      context,
                      icon: Icons.event_note_rounded, // Modern icon
                      label: 'Rendezvous',
                      count: rendezvousCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RendezVousListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kBluePurple // Using the new constant
                          .withOpacity(0.9), // A nice blue-purple
                      iconColor: Colors.white,
                      labelTextStyle: cardLabelTextStyle,
                      countTextStyle: cardCountValueTextStyle,
                    ),
                    _buildHomeCard(
                      context,
                      icon: Icons.people_alt_rounded, // Modern icon
                      label: 'Clients',
                      count: clientsCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientsListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kPrimaryGreen
                          .withOpacity(0.9), // Another themed card color
                      iconColor: Colors.white,
                      labelTextStyle: cardLabelTextStyle,
                      countTextStyle: cardCountValueTextStyle,
                    ),
                    _buildHomeCard(
                      context,
                      icon: Icons.local_hospital_rounded, // Modern icon
                      label: 'Consultations',
                      count: consultationsCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConsultationListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kStrongRed // Using the new constant
                          .withOpacity(0.9), // A strong red
                      iconColor: Colors.white,
                      labelTextStyle: cardLabelTextStyle,
                      countTextStyle: cardCountValueTextStyle,
                    ),
                    _buildHomeCard(
                      context,
                      icon: Icons.vaccines_rounded, // Modern icon
                      label: 'Vaccinations',
                      count: vaccinationsCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VaccinationListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kWarmOrange // Using the new constant
                          .withOpacity(0.9), // A warm orange
                      iconColor: Colors.white,
                      labelTextStyle: cardLabelTextStyle,
                      countTextStyle: cardCountValueTextStyle,
                    ),
                    _buildHomeCard(
                      context,
                      icon: Icons.shopping_bag_rounded, // Modern icon
                      label: 'Products',
                      count: productCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsListPage(
                              token: widget.token,
                              username: widget.username,
                            ),
                          ),
                        ).then((_) => _fetchDataCounts());
                      },
                      cardColor: kTealGreen // Using the new constant
                          .withOpacity(0.9), // A teal green
                      iconColor: Colors.white,
                      labelTextStyle: cardLabelTextStyle,
                      countTextStyle: cardCountValueTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color cardColor,
        required Color iconColor,
        required TextStyle labelTextStyle,
        required TextStyle countTextStyle,
        int? count,
      }) {
    return Card(
      elevation: 8, // More pronounced shadow
      color: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)), // More rounded corners
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Consistent padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: iconColor), // REDUCED Icon size
              const SizedBox(height: 8), // REDUCED SizedBox height
              Text(
                label,
                style: labelTextStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null) ...[
                const SizedBox(height: 6), // REDUCED SizedBox height
                // Themed count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 12), // REDUCED vertical padding
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.2), // Subtle white overlay for the count
                    borderRadius: BorderRadius.circular(15), // Rounded badge
                  ),
                  child: Text(
                    count.toString(),
                    style: countTextStyle,
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