import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { VeterinaireService } from '../../services/veterinaire.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-consultation-veterinaire',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './consultation-veterinaire.component.html',
  styleUrls: ['./consultation-veterinaire.component.css']
})
export class ConsultationVeterinaireComponent implements OnInit {
  consultations: any[] = [];


  constructor(private route: ActivatedRoute, private vetService: VeterinaireService) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.vetService.getconsultationByVet(id).subscribe({
        next: (res: any[]) => this.consultations = res,
        error: err => console.error('Erreur lors de la récupération des consultations', err)
      });
    }
  }
}
