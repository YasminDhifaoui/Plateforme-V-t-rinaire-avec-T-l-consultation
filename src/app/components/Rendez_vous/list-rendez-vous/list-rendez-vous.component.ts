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
import { AddRendezVousComponent } from '../add-rendez-vous/add-rendez-vous.component';
import { UpdateRendezVousComponent } from '../update-rendez-vous/update-rendez-vous.component';

@Component({
  selector: 'app-list-rendez-vous',
  imports: [MatTableModule,MatPaginatorModule,CommonModule,MatIconModule,FormsModule,CommonModule,RouterModule],
  templateUrl: './list-rendez-vous.component.html',
  styleUrl: './list-rendez-vous.component.css'
})
export class ListRendezVousComponent implements OnInit{
  constructor(private dialog: MatDialog,private RendezVousService: RendezVousService,private router: Router) {}

  displayedColumns: string[] = ['vetid', 'clid', 'date','status','actions'];
  dataSource = new MatTableDataSource<RendezVous>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.RendezVousService.getAllrendezvous().subscribe(
      (res: any) => {
        console.log(res);
        
        if (Array.isArray(res)) {
          this.dataSource.data = res as RendezVous[];
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
  AddRendezVousDialog() {
    const dialogRef = this.dialog.open(AddRendezVousComponent, {
      width: '400px',
      ariaDescribedBy: 'add-RendezVous-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau RendezVous:', result);
      }
    });
  }
  UpdateRendezVousDialog(client: any) {
    const dialogRef = this.dialog.open(UpdateRendezVousComponent, {
      width: '400px',
      ariaDescribedBy: 'update-RendezVous-description',
      data: client   // ici tu envoies tout l'objet
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('RendezVous modifié avec succès:', result);
      }
    });
  }
  
  
  deleteRendezVous(id: any) {
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
        this.RendezVousService.Deleterendezvous(id).subscribe(
          res => {
            console.log('RendezVous supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'Le RendezVous a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.router.navigate(['/RendezVous']); 
              this.ngOnInit()
            });
          },
          err => {
            console.log('Erreur lors de la suppression du RendezVous', err);
              Swal.fire({
              title: 'Erreur',
              text: 'Une erreur est survenue lors de la suppression du RendezVous.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        );
      }
    });
  }
}

export interface RendezVous {
  Vetid: string;
  clid: string;
  date: Date;
  status: string;

}






