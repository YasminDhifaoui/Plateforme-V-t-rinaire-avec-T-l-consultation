import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule, MatLabel } from '@angular/material/form-field';
import { Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import Swal from 'sweetalert2';
import { firstValueFrom, race } from 'rxjs';
import { AnimalService } from '../../../animal.service';

@Component({
  selector: 'app-add-animal',
  imports: [CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,

    MatFormFieldModule],
  templateUrl: './add-animal.component.html',
  styleUrl: './add-animal.component.css'
})
export class AddAnimalComponent {
  animalForm: FormGroup;
  

  constructor(
    public dialogRef: MatDialogRef<AddAnimalComponent>,
    private fb: FormBuilder,
    private router: Router,
    private animalService: AnimalService
  ) {
    this.animalForm = this.fb.group({
      name: ['', Validators.required],
      espece: ['', [Validators.required]],
      race: ['', [Validators.required]],
      age: ['', [Validators.required]],
      sexe: ['', [Validators.required]],
      allergies: ['', [Validators.required]],
      antecedentsMedicaux: ['', [Validators.required]],
      ownerId: ['', [Validators.required]],
    });
  }
  async onSubmit(): Promise<void> {
    if (this.animalForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const formData = this.animalForm.value;
      console.log('Form Data:', formData);
  
      const response = await firstValueFrom(this.animalService.AddAnimal(formData));
      console.log('Animal ajouté avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Animal ajouté avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du client:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout de l animal.';
  
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



