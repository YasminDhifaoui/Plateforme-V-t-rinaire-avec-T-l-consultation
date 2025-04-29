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
import { VaccinationService } from '../../../services/vaccination.service';
import { AnimalService } from '../../../animal.service';
import { AddVaccinationComponent } from '../add-vaccination/add-vaccination.component';
import { UpdateVaccinationComponent } from '../update-vaccination/update-vaccination.component';


@Component({
  selector: 'app-list-vaccination',
  imports: [MatTableModule,MatPaginatorModule,CommonModule,MatIconModule,FormsModule,CommonModule,RouterModule],
  templateUrl: './list-vaccination.component.html',
  styleUrl: './list-vaccination.component.css'
})
export class ListVaccinationComponent {
  constructor(private dialog: MatDialog,private AnimalService: AnimalService,private router: Router,private VaccinationService: VaccinationService) {}
veterinare: any[]= []; 
  displayedColumns: string[] = ['name','date','animalId','actions'];
  dataSource = new MatTableDataSource<vaccination>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.VaccinationService.getAllvaccination().subscribe(
      (res: any) => {
        console.log(res);
        
        if (Array.isArray(res)) {
          this.dataSource.data = res as vaccination[];
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
  AddvaccinationDialog() {
    const dialogRef = this.dialog.open(AddVaccinationComponent, {
      width: '400px',
      ariaDescribedBy: 'add-vaccination-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau vaccination:', result);
      }
    });
  }
  UpdatevaccinationDialog(client: any) {
    const dialogRef = this.dialog.open(UpdateVaccinationComponent, {
      width: '400px',
      ariaDescribedBy: 'update-vaccination-description',
      data: client   // ici tu envoies tout l'objet
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('vaccination modifié avec succès:', result);
      }
    });
  }

  
  deletevaccination(id: any) {
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
        this.VaccinationService.Deletevaccination(id).subscribe(
          res => {
            console.log('vaccination supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'Le vaccination a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.router.navigate(['/vaccination']); 
              this.ngOnInit()
            });
          },
          err => {
            console.log('Erreur lors de la suppression du vaccination', err);
              Swal.fire({
              title: 'Erreur',
              text: 'Une erreur est survenue lors de la suppression du vaccination.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        );
      }
    });
  }
}

export interface vaccination {
  name: string;
  date: Date;
  animalId: string;
  
 

}









