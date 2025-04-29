import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule, MatLabel } from '@angular/material/form-field';
import { Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';

import { AdminService } from '../../../services/admin.service';


@Component({
  selector: 'app-add-admin',
  imports: [ CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,

    MatFormFieldModule,],
  templateUrl: './add-admin.component.html',
  styleUrl: './add-admin.component.css'
})
export class AddAdminComponent {
  adminForm: FormGroup;
  

  constructor(
    public dialogRef: MatDialogRef<AddAdminComponent>,
    private fb: FormBuilder,
    private router: Router,
    private AdminService: AdminService
  ) {
    this.adminForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required]],
      password: ['', [Validators.required]],
    });
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
      const formData = this.adminForm.value;
      console.log('Form Data:', formData);
  
      const response = await firstValueFrom(this.AdminService.Addadmin(formData));
      console.log('admin ajouté avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'admin ajouté avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du admin:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout du admin.';
  
      await Swal.fire({
        title: 'Erreur',
        text: errorMessage,
        icon: 'error'
      });
    }
  }
  
  close(): void {
    this.dialogRef.close(false);
  }
 
}



