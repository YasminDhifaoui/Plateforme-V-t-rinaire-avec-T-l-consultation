import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { AddClientComponent } from '../add-client/add-client.component';
import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { ClientService } from '../../../services/client.service';
import Swal from 'sweetalert2';
import { Router, RouterModule } from '@angular/router';
import { UpdateClientComponent } from '../update-client/update-client.component';

@Component({
  selector: 'app-clients',
  imports: [MatTableModule,MatPaginatorModule,CommonModule,MatIconModule,FormsModule,CommonModule,RouterModule],
  templateUrl: './clients.component.html',
  styleUrl: './clients.component.css'
})
export class ClientsComponent implements OnInit{
  constructor(private dialog: MatDialog,private clientService: ClientService,private router: Router) {}

  displayedColumns: string[] = ['id', 'username', 'email','actions'];
  dataSource = new MatTableDataSource<Client>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.clientService.getAllClients().subscribe(
      (res: any) => {
        console.log(res);
        
        if (Array.isArray(res)) {
          this.dataSource.data = res as Client[];
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
  AddClientDialog() {
    const dialogRef = this.dialog.open(AddClientComponent, {
      width: '400px',
      ariaDescribedBy: 'add-client-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau client:', result);
        this.ngOnInit()
      }
    });
  }
  goToAnimals(vetId: string) {
    this.router.navigate(['/client-animal', vetId]);
  }
  
  UpdateClientDialog(client: any) {
    const dialogRef = this.dialog.open(UpdateClientComponent, {
      width: '400px',
      ariaDescribedBy: 'update-client-description',
      data: client
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        // Refresh the client list
        this.clientService.getAllClients().subscribe(
          (res: any) => {
            if (Array.isArray(res)) {
              this.dataSource.data = res as Client[];
              this.ngOnInit()
            }
          }
        );
      }
    });
  }
  
  
  deleteClient(id: any) {
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
        this.clientService.DeleteClient(id).subscribe(
          res => {
            console.log('Client supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'Le client a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
            }).then(() => {
              this.router.navigate(['/clients']); 
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

export interface Client {
  id: string;
  username: string;
  email: string;
  

}



