import { Component } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import Swal from 'sweetalert2';
import { VeterinaireService } from '../../../services/veterinaire.service';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';

@Component({
  selector: 'app-add-veterinaire',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
  ],
  templateUrl: './add-veterinaire.component.html',
  styleUrl: './add-veterinaire.component.css'
})
export class AddVeterinaireComponent {
  veterinaireForm: FormGroup
  constructor(
    public dialogRef: MatDialogRef<AddVeterinaireComponent>,
    private fb: FormBuilder,
    private router: Router,
    private veterinaireService: VeterinaireService
  ) {
    this.veterinaireForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required]],
      password: ['', [Validators.required]],
      phoneNumber: ['',[Validators.required]]
    });
  }
  async onSubmit(): Promise<void> {
    if (this.veterinaireForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const formData = this.veterinaireForm.value;
      console.log('Form Data:', formData);
  
      const response = await firstValueFrom(this.veterinaireService.AddVeterinaire(formData));
      console.log('Veterinaire ajouté avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Veterinaire ajouté avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(response);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du Veterinaire:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout du Veterinaire.';
  
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
