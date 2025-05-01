import 'package:flutter/material.dart';

enum RendezvousStatus {
  confirme,
  annule,
  termine,
}

extension RendezvousStatusExtension on RendezvousStatus {
  String get label {
    switch (this) {
      case RendezvousStatus.confirme:
        return 'Confirmé';
      case RendezvousStatus.annule:
        return 'Annulé';
      case RendezvousStatus.termine:
        return 'Terminé';
    }
  }

  Color get color {
    switch (this) {
      case RendezvousStatus.confirme:
        return Colors.green;
      case RendezvousStatus.annule:
        return Colors.red;
      case RendezvousStatus.termine:
        return Colors.grey;
    }
  }
}

class Rendezvous {
  final String id;
  final DateTime date;
  final String vetName;
  final String animalName;
  final RendezvousStatus status;

  Rendezvous({
    required this.id,
    required this.date,
    required this.vetName,
    required this.animalName,
    required this.status,
  });

  factory Rendezvous.fromJson(Map<String, dynamic> json) {
    return Rendezvous(
      id: json['id'],
      date: DateTime.parse(json['date']),
      vetName: json['vetName'],
      animalName: json['animalName'],
      status: RendezvousStatus.values.elementAt(json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'vetName': vetName,
      'animalName': animalName,
      'status': status.index, // send as int
    };
  }
}
