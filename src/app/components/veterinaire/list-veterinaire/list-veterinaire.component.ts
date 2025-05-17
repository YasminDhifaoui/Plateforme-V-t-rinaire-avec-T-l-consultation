import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { VeterinaireService } from '../../../services/veterinaire.service';
import Swal from 'sweetalert2';
import { Router, RouterModule } from '@angular/router';
import { AddVeterinaireComponent } from '../add-veterinaire/add-veterinaire.component';
import { UpdateVeterinaireComponent } from '../update-veterinaire/update-veterinaire.component';




// Tu ajouteras ces composants si tu veux des dialogues comme pour les clients
// import { AddVeterinaireComponent } from '../add-veterinaire/add-veterinaire.component';
// import { UpdateVeterinaireComponent } from '../update-veterinaire/update-veterinaire.component';

@Component({
  selector: 'app-list-veterinaire',
  standalone: true, // à retirer si utilisé dans un module Angular classique
  imports: [
    
    MatTableModule,
    MatPaginatorModule,
    CommonModule,
    MatIconModule,
    FormsModule,
    RouterModule,
    // AddVeterinaireComponent,
    // UpdateVeterinaireComponent
  ],
  templateUrl: './list-veterinaire.component.html',
  styleUrls: ['./list-veterinaire.component.css']
})
export class ListVeterinaireComponent implements OnInit {
  displayedColumns: string[] = ['id', 'nom', 'email', 'numero', 'actions'];
  dataSource = new MatTableDataSource<Veterinaire>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  constructor(private veterinaireService: VeterinaireService, private dialog: MatDialog, private router: Router) {}

  ngOnInit(): void {
    this.veterinaireService.getAllVeterinaires().subscribe(
      (res: any) => {
        console.log("res:", res);  // Afficher la réponse complète
        
        if (Array.isArray(res)) {
          this.dataSource.data = res as Veterinaire[];
          console.log("Data Source:", this.dataSource.data); // Afficher ce qui est assigné à dataSource
        } else {
          console.error('Unexpected data format:', res);
        }
      },
      error => {
        console.error('Error fetching veterinaires:', error);
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
  AddVetDialog() {
    const dialogRef = this.dialog.open(AddVeterinaireComponent, {
      width: '400px',
      ariaDescribedBy: 'add-vet-description'
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau vétérinaire:', result);
        // Ajouter le nouveau vétérinaire à la table sans recharger
        this.dataSource.data = [...this.dataSource.data, result];
        this.ngOnInit()
      }
    });
  }
  goToConsultations(vetId: string) {
    this.router.navigate(['/consultations-veterinaire', vetId]);
  }
  
  
  
  UpdateVeterinareDialog(veterinaire: any) {
   const dialogRef = this.dialog.open(UpdateVeterinaireComponent, {
         width: '400px',
         ariaDescribedBy: 'update-vet-description',
         data: veterinaire   
       });
     
       dialogRef.afterClosed().subscribe(result => {
        if (result) {
          console.log('vet modifié avec succès:', result);
          this.ngOnInit(); // 🔁 Recharge la liste après modification
        }
      });
      
  }
  
    
    deleteVet(id: any) {
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
          this.veterinaireService.DeleteVeterinaire(id).subscribe(
            res => {
              console.log('Client supprimé avec succès', res);
              Swal.fire({
                title: 'Supprimé !',
                text: 'Le client a été supprimé avec succès.',
                icon: 'success',
                confirmButtonText: 'OK'
              }).then(() => {
                this.router.navigate(['/veterinaires']); 
                this.ngOnInit()
              });
            },
            err => {
              console.log('Erreur lors de la suppression du client', err);
                Swal.fire({
                title: 'Erreur',
                text: 'Une erreur est survenue lors de la suppression du client.',
                icon: 'error',
                confirmButtonText: 'OK'
              });
            }
          );
        }
      });
    }

}

export interface Veterinaire {
  id: string;
  username: string;
  email: string;
  phoneNumber: string;
  role: string;
}
