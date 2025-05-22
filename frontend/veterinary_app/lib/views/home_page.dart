import 'package:flutter/material.dart';
import 'package:veterinary_app/utils/base_url.dart';
import 'package:veterinary_app/utils/logout_helper.dart';
import 'package:veterinary_app/views/consultation_pages/consultation_page.dart';
import 'package:veterinary_app/views/product_pages/products_list_page.dart';
import 'package:veterinary_app/views/rendezvous_pages/rendezvous_list_page.dart';
import 'package:veterinary_app/views/animal_pages/animals_list_page.dart';
import 'package:veterinary_app/views/client_pages/clients_list_page.dart'; // <-- Import the client page
import 'package:veterinary_app/views/vaccination_pages/vaccination_list_page.dart'; // <-- Import the vaccination list page
import 'package:veterinary_app/services/animal_services/animals_vet_service.dart'; // Import AnimalsVetService
import 'package:veterinary_app/services/rendezvous_services/rendezvous_service.dart'; // Import RendezVousService
import 'package:veterinary_app/services/client_services/client_service.dart'; // Import ClientService
import 'package:veterinary_app/services/consultation_services/consultation_service.dart'; // Import ConsultationService
import 'package:veterinary_app/services/product_services/product_service.dart';

import 'package:veterinary_app/services/vaccination_services/vaccination_service.dart'; // Import VaccinationService
import 'components/home_navbar.dart';

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

  final ProductService _productService = ProductService(
    baseUrl: "${BaseUrl.api}/api/vet",
  );

  int animalCount = 0;
  int rendezvousCount = 0;
  int clientsCount = 0;
  int consultationsCount = 0;
  int vaccinationsCount = 0;
  int productCount = 8;

  @override
  void initState() {
    super.initState();
    _fetchDataCounts();
  }

  Future<void> _fetchDataCounts() async {
    await Future.wait([
      _fetchAnimalCount(),
      _fetchRendezvousCount(),
      _fetchClientsCount(),
      _fetchConsultationsCount(),
      _fetchVaccinationsCount(),
      _fetchProductCount(),
    ]);
  }

  Future<void> _fetchAnimalCount() async {
    try {
      final animals = await _animalsVetService.getAnimalsList(widget.token);
      setState(() {
        animalCount = animals.length;
      });
    } catch (e) {
      setState(() {
        animalCount = 0;
      });
    }
  }

  Future<void> _fetchRendezvousCount() async {
    try {
      final rendezvous = await _rendezVousService.getRendezVousList(
        widget.token,
      );
      setState(() {
        rendezvousCount = rendezvous.length;
      });
    } catch (e) {
      setState(() {
        rendezvousCount = 0;
      });
    }
  }

  Future<void> _fetchClientsCount() async {
    try {
      final clients = await _clientService.getAllClients(widget.token);
      setState(() {
        clientsCount = clients.length;
      });
    } catch (e) {
      setState(() {
        clientsCount = 0;
      });
    }
  }

  Future<void> _fetchConsultationsCount() async {
    try {
      final consultations = await ConsultationService.fetchConsultations(
        widget.token,
      );
      setState(() {
        consultationsCount = consultations.length;
      });
    } catch (e) {
      setState(() {
        consultationsCount = 0;
      });
    }
  }

  Future<void> _fetchVaccinationsCount() async {
    try {
      final vaccinations = await _vaccinationService.getAllVaccinations(
        widget.token,
      );
      setState(() {
        vaccinationsCount = vaccinations.length;
      });
    } catch (e) {
      setState(() {
        vaccinationsCount = 0;
      });
    }
  }

  Future<void> _fetchProductCount() async {
    try {
      final products = await _productService.getAllProducts(widget.token);
      setState(() {
        productCount = products.length;
      });
    } catch (e) {
      print('Error fetching products: $e');

      setState(() {
        productCount = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey[900],
    );
    final cardIconColor = Colors.blueAccent;

    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            children: [
              const SizedBox(height: 32),
              // The first GridView with home cards is kept, but counts are added
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                children: [
                  _buildHomeCard(
                    context,
                    icon: Icons.pets,
                    label: 'Animals',
                    count: animalCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AnimalsListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                    cardColor: Colors.orangeAccent.withOpacity(0.6),
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.event,
                    label: 'RDV',
                    count: rendezvousCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RendezVousListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                    cardColor: Colors.lightBlueAccent.withOpacity(0.6),
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.people,
                    label: 'Clients',
                    count: clientsCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ClientsListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                    cardColor: Colors.greenAccent.withOpacity(0.6),
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.medical_services,
                    label: 'Consultations',
                    count: consultationsCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ConsultationListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                    cardColor: Colors.purpleAccent.withOpacity(0.6),
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.vaccines,
                    label: 'Vaccinations',
                    count: vaccinationsCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => VaccinationListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: cardIconColor,
                    cardColor: Colors.redAccent.withOpacity(0.6),
                  ),
                  _buildHomeCard(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Products',
                    count: productCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProductsListPage(
                                token: widget.token,
                                username: widget.username,
                              ),
                        ),
                      );
                    },
                    textStyle: cardTextStyle,
                    iconColor: Colors.deepOrange,
                    cardColor: Colors.deepOrangeAccent.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Removed the second GridView with count cards
              // Instead, counts are shown inside the home cards
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
