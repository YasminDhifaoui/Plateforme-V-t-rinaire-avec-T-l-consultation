import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';

import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';

import Swal from 'sweetalert2';
import { Router, RouterModule } from '@angular/router';
import { AdminService } from '../../../services/admin.service';
import { AddAdminComponent } from '../add-admin/add-admin.component';
import { UpdateAdminComponent } from '../update-admin/update-admin.component';


@Component({
  selector: 'app-list-admin',
  imports: [MatTableModule,MatPaginatorModule,CommonModule,MatIconModule,FormsModule,CommonModule,RouterModule],
  templateUrl: './list-admin.component.html',
  styleUrl: './list-admin.component.css'
})
export class ListAdminComponent {
  constructor(private dialog: MatDialog,private AdminService: AdminService,private router: Router) {}

  displayedColumns: string[] = ['id', 'username', 'email','actions'];
  dataSource = new MatTableDataSource<Admin>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.loadAdmins();
}
  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
  }
  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }
  AddAdminDialog() {
    const dialogRef = this.dialog.open(AddAdminComponent, {
      width: '400px',
      ariaDescribedBy: 'add-Admin-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Nouveau admin:', result);
        this.ngOnInit()
      }
    });
  }
  UpdateAdminDialog(Admin: any) {
    const dialogRef = this.dialog.open(UpdateAdminComponent, {
      width: '400px',
      ariaDescribedBy: 'update-Admin-description',
      data: Admin   // ici tu envoies tout l'objet
    });
  
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Admin modifié avec succès:', result);
        this.ngOnInit()
      }
    });
  }
  
  
  deleteAdmin(id: any) {
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
        this.AdminService.Deleteadmin(id).subscribe(
          res => {
            console.log('Admin supprimé avec succès', res);
            Swal.fire({
              title: 'Supprimé !',
              text: 'La Admin a été supprimé avec succès.',
              icon: 'success',
              confirmButtonText: 'OK'
              
            }).then(() => {
              this.router.navigate(['/admins']); 
              this.ngOnInit()
            });
          },
          err => {
            console.log('Erreur lors de la suppression du Admin', err);
              Swal.fire({
              title: 'Erreur',
              text: 'Une erreur est survenue lors de la suppression du Admin.',
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        );
      }
    });
  }

loadAdmins(): void {
  this.AdminService.getAlladmins().subscribe(
    (res: any) => {
      console.log(res);
      
      if (Array.isArray(res)) {
        this.dataSource.data = res as Admin[];
      } else {
        console.error('Unexpected data format:', res);
      }
    }
  );
}}
export interface Admin {
  id: string;
  username: string;
  email: string;

}






