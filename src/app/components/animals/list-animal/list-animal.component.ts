import { Component, ViewChild } from '@angular/core';
import { AnimalService } from '../../../animal.service';
import { Router, RouterModule } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ClientService } from '../../../services/client.service';
import { AddAnimalComponent } from '../add-animal/add-animal.component';
import { UpdateAnimalComponent } from '../update-animal/update-animal.component';


import Swal from 'sweetalert2';
@Component({
  selector: 'app-list-animal',
  imports: [MatTableModule,MatPaginatorModule,CommonModule,MatIconModule,FormsModule,CommonModule,RouterModule],

  templateUrl: './list-animal.component.html',
  styleUrl: './list-animal.component.css'
})
export class ListAnimalComponent {
  constructor(
    private dialog: MatDialog,
    private animalService: AnimalService,
    private router: Router,
    private clientService: ClientService
  ) {}

  displayedColumns: string[] = ['id', 'nom', 'race', 'sexe', 'allergies', 'owner', 'actions'];
  dataSource = new MatTableDataSource<Animal & { ownerName: string }>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.loadAnimalsWithOwners();
  }

  loadAnimalsWithOwners(): void {
    this.animalService.getAllAnimals().subscribe({
      next: (animals: any) => {  // Changed to 'any' to match the expected type
        if (Array.isArray(animals)) {
          const animalsWithOwners = animals.map(animal => {
            const animalWithOwner = { ...animal, ownerName: 'Loading...' };
            
            if (animal.ownerId) {
              this.clientService.getClientById(animal.ownerId).subscribe({
                next: (client: any) => {
                  animalWithOwner.ownerName = client.username || 'Unknown';
                  this.dataSource.data = [...this.dataSource.data];
                },
                error: () => {
                  animalWithOwner.ownerName = 'Not Found';
                }
              });
            } else {
              animalWithOwner.ownerName = 'No Owner';
            }
            
            return animalWithOwner;
          });
          
          this.dataSource.data = animalsWithOwners;
          if (this.paginator) {
            this.dataSource.paginator = this.paginator;
          }
        } else {
          console.error('Unexpected data format:', animals);
        }
      },
      error: (err) => {
        console.error('Error loading animals:', err);
      }
    });
  }

ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
  }
  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }
  AddanimalDialog() {
    const dialogRef = this.dialog.open(AddAnimalComponent, {
      width: '400px',
      ariaDescribedBy: 'add-animal-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau Animal:', result);
        this.ngOnInit(); // Recharge les données
      }
    });
  }

  UpdateanimalDialog(animal: any) {
    const dialogRef = this.dialog.open(UpdateAnimalComponent, {
      width: '400px',
      ariaDescribedBy: 'update-animal-description',
      data: animal
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Animal modifié avec succès:', result);
        this.ngOnInit(); // Recharge les données
      }
    });
  }

  deleteanimal(id: any) {
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
        this.animalService.DeleteAnimal(id).subscribe( // <-- Attention : utiliser `animalService` et non `clientService` ici !
          res => {
            console.log('Animal supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'L\'animal a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.ngOnInit();
            });
          },
          err => {
            console.log('Erreur lors de la suppression de l\'animal', err);
            Swal.fire({
              title: 'Erreur',
              text: 'Une erreur est survenue lors de la suppression de l\'animal.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        );
      }
    });
  }}

export interface Animal {
  id: string;
  nom: string;
  race: string;
  sexe: string;
  allergies: string;

}

