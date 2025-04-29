import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { ClientService } from '../../../services/client.service';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { AdminService } from '../../../services/admin.service';

@Component({
  selector: 'app-update-admin',
  imports: [ CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,],
  templateUrl: './update-admin.component.html',
  styleUrl: './update-admin.component.css'
})
export class UpdateAdminComponent {
  adminForm: FormGroup;
  adminId: any;

  constructor(
    public dialogRef: MatDialogRef<UpdateAdminComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private adminService: AdminService
  ) {
    this.adminForm = this.fb.group({
      username: [''],
      email: [''],
      password: ['']
    });
  }

  ngOnInit(): void {
    if (this.data) {
      console.log(this.data);
      
      this.adminId = this.data.id;
      this.adminForm.patchValue({
        username: this.data.username,
        email: this.data.email,
        password: this.data.password
      });
    }
  }

  async onSubmit(): Promise<void> {
    if (this.adminForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const payload = {
        updatedAdmin: this.adminForm.value
      };
  
      const response = await firstValueFrom(
        this.adminService.Updateadmin(payload, this.adminId)
      );
  
      console.log('admin modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'admin modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du admin:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de la modification.';
  
      await Swal.fire({
        title: 'Erreur',
        text: errorMessage,
        icon: 'error'
      });
    }
  }
  

  close(): void {
    this.dialogRef.close();
  }
}



