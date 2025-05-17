import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ClientService } from '../../services/client.service';
import { VeterinaireService } from '../../services/veterinaire.service';
import { AnimalService } from '../../animal.service';
import { ConsultationService } from '../../services/consultation.service';
import { VaccinationService } from '../../services/vaccination.service';
import { RendezVousService } from '../../services/rendez-vous.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css']
})
export class AdminDashboardComponent implements OnInit {

  clientsCount: number = 0;
  veterinariesCount: number = 0;
  animalsCount: number = 0;
  consultationsCount: number = 0;
  vaccinationsCount: number = 0;
  rendezVousCount: number = 0;

  urgentRendezvous: any[] = [];
  vaccinationsDueToday: any[] = [];
  consultationsToday: any[] = [];

  
  constructor(
    private router: Router,
    private clientService: ClientService,
    private veterinaireService: VeterinaireService,
    private animalService: AnimalService,
    private consultationService: ConsultationService,
    private vaccinationService: VaccinationService,
    private rendezVousService: RendezVousService
  ) {}

  ngOnInit(): void {
    this.clientService.getAllClients().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.clientsCount = res.length;
      }
    });

    this.veterinaireService.getAllVeterinaires().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.veterinariesCount = res.length;
      }
    });

    this.animalService.getAllAnimals().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.animalsCount = res.length;
      }
    });

    this.consultationService.getAllconsultations().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.consultationsCount = res.length;
      }
    });

    this.vaccinationService.getAllvaccination().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.vaccinationsCount = res.length;
      }
    });

    this.rendezVousService.getAllrendezvous().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.rendezVousCount = res.length;
      }
    });

    this.rendezVousService.getUrgentRendezvousToday().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.urgentRendezvous = res;
      }
    });

    this.consultationService.getConsultationsToday().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.consultationsToday = res;
      }
    });

    this.vaccinationService.getVaccinationsDueToday().subscribe((res: any) => {
      if (Array.isArray(res)) {
        this.vaccinationsDueToday = res;
      }
    });
  }

  navigateTo(route: string) {
    this.router.navigate(['/' + route]);
  }
}
