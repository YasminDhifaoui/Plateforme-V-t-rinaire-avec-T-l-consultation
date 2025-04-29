import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { RendezVousService } from '../../../services/rendez-vous.service';
import Swal from 'sweetalert2';
import { Router, RouterModule } from '@angular/router';
import { VeterinaireService } from '../../../services/veterinaire.service';
import { ConsultationService } from '../../../services/consultation.service';
import { AddConsultationComponent } from '../add-consultation/add-consultation.component';
import { UpdateConsultationComponent } from '../update-consultation/update-consultation.component';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSortModule } from '@angular/material/sort';
import { firstValueFrom } from 'rxjs';
@Component({
  selector: 'app-list-consultation',
  imports: [MatPaginatorModule,
    MatTableModule, MatTableModule,
    MatPaginatorModule,
    MatIconModule,
    MatInputModule,
    MatButtonModule,
    MatSortModule,CommonModule,],
  templateUrl: './list-consultation.component.html',
  styleUrl: './list-consultation.component.css'
})
export class ListConsultationComponent {
  constructor(private dialog: MatDialog,private verterinareService: VeterinaireService,private ConsultationService: ConsultationService,private router: Router,private verterinareServcie: VeterinaireService) {}
veterinare: any[]= []; 
displayedColumns: string[] = ['rendezVousId', 'veterinaireName', 'animalId', 'date', 'actions'];
  dataSource = new MatTableDataSource<consultation>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.ConsultationService.getAllconsultations().subscribe(
      async (res: any) => {
        console.log("Consultations récupérées:", res);
  
        if (Array.isArray(res)) {
          const consultations = await Promise.all(res.map(async (consultation) => {
            if (consultation.veterinaireId) {
              try {
                const vet = await firstValueFrom(this.verterinareService.getVeterinaireById(consultation.veterinaireId));
                consultation.veterinaireName = vet.username; 
              } catch (err) {
                console.error('Erreur récupération vétérinaire', err);
                consultation.veterinaireName = 'Non trouvé';
              }
            }
            return consultation;
          }));
  
          this.dataSource.data = consultations;
        } else {
          console.error('Unexpected data format:', res);
        }
      }
    );
  }
  
 
  
  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
  }
  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }
  AddconsultationDialog() {
    const dialogRef = this.dialog.open(AddConsultationComponent, {
      width: '400px',
      ariaDescribedBy: 'add-consultation-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau consultation:', result);
      }
    });
  }
  UpdateconsultationDialog(client: any) {
    const dialogRef = this.dialog.open(UpdateConsultationComponent, {
      width: '400px',
      ariaDescribedBy: 'update-consultation-description',
      data: client   // ici tu envoies tout l'objet
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('consultation modifié avec succès:', result);
      }
    });
  }

  
  deleteconsultation(id: any) {
    Swal.fire({
      title: 'Êtes-vous sûr ?',
      text: 'Vous ne pourrez pas annuler cette action !',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Oui, supprimer !',
      cancelButtonText: 'Annuler'
    }).then((result) => {
      if (result.isConfirmed) {
        this.ConsultationService.Deleteconsultations(id).subscribe(
          res => {
            console.log('consultation supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'La consultation a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.router.navigate(['/consultation']); 
              this.ngOnInit()
            });
          },
          err => {
            console.log('Erreur lors de la suppression du consultation', err);
              Swal.fire({
              title: 'Erreur',
              text: 'Une erreur est survenue lors de la suppression du consultation.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        );
      }
    });
  }
}

export interface consultation {
  id: string;
  rendezVousId: string;
  veterinaireId: string;
  animalId: string;
  date: Date;
  veterinaireName?: string; // <== ajouter cette ligne pour dire que veterinaireName est possible
}



