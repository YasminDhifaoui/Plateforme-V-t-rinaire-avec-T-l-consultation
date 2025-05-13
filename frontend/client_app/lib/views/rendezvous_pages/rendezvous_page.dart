import 'package:client_app/services/rendezvous_services/rendezvous_service.dart';
import 'package:client_app/views/rendezvous_pages/update_rendezvous_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_app/models/rendezvous_models/rendezvous.dart';
import 'package:client_app/services/rendezvous_services/delete_rendezvous.dart';
import 'package:client_app/views/components/home_navbar.dart';
import 'package:client_app/utils/logout_helper.dart';

import '../vet_pages/veterinary_page.dart';

class RendezvousPage extends StatefulWidget {
  final String username;

  const RendezvousPage({Key? key, required this.username}) : super(key: key);

  @override
  State<RendezvousPage> createState() => _RendezvousPageState();
}

class _RendezvousPageState extends State<RendezvousPage> {
  late Future<List<Rendezvous>> _rendezvousFuture;

  @override
  void initState() {
    super.initState();
    _rendezvousFuture = RendezvousService().getRendezvousList();
  }

  Future<void> _refreshRendezvous() async {
    setState(() {
      _rendezvousFuture = RendezvousService().getRendezvousList();
    });
  }

  String _getStatusText(RendezvousStatus status) {
    switch (status) {
      case RendezvousStatus.confirme:
        return 'Confirmé';
      case RendezvousStatus.annule:
        return 'Annulé';
      case RendezvousStatus.termine:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  void _deleteRendezvous(String id) async {
    try {
      await DeleteRendezvousService().deleteRendezvous(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous supprimé')),
      );
      _refreshRendezvous();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de suppression: $e')),
      );
    }
  }

  Widget _buildRendezvousCard(Rendezvous rv) {
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(rv.date);
    final statusText = _getStatusText(rv.status);

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          formattedDate,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Vétérinaire : ${rv.vetName}'),
            Text('Animal : ${rv.animalName}'),
            Text('Date : $formattedDate'),
            Text('Statut : $statusText'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'update') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateRendezvousPage(),
                  settings: RouteSettings(arguments: {
                    'rendezvous': rv,
                    'vetName': rv.vetName,
                  }),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text(
                      'Are you sure you want to cancel the appointment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                _deleteRendezvous(rv.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'update', child: Text('change')),
            const PopupMenuItem(value: 'delete', child: Text('cancel')),
          ],
          icon: const Icon(Icons.more_vert, color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeNavbar(
        username: widget.username,
        onLogout: () => LogoutHelper.handleLogout(context),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My appointments  ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VetListPage(username: widget.username), // Pass widget.username
                      ),
                    );

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Button color
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Rounded corners
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'View Vets List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshRendezvous,
              child: FutureBuilder<List<Rendezvous>>(
                future: _rendezvousFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Aucun rendez-vous trouvé.'));
                  }

                  final rendezvousList = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: rendezvousList.length,
                    itemBuilder: (context, index) =>
                        _buildRendezvousCard(rendezvousList[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
