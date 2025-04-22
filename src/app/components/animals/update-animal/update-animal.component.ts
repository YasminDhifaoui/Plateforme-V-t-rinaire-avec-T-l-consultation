import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import Swal from 'sweetalert2';
import { firstValueFrom, race } from 'rxjs';
import { ClientService } from '../../../services/client.service';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { AnimalService } from '../../../animal.service';
import { escape } from 'querystring';

@Component({
  selector: 'app-update-animal',
  imports: [CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,],
  templateUrl: './update-animal.component.html',
  styleUrl: './update-animal.component.css'
})
export class UpdateAnimalComponent {
  animalForm: FormGroup;
  onimalId: any;

  constructor(
    public dialogRef: MatDialogRef<UpdateAnimalComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private animalService: AnimalService
  ) {
    this.animalForm = this.fb.group({
      name: ['', Validators.required],
      espece: ['', Validators.required],
      race: ['', Validators.required],
      age: ['', Validators.required],
      sexe: ['', Validators.required],
      allergies: [''],
      antecedentsMedicaux: [''],
      ownerId: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    if (this.data) {
      console.log(this.data);
      
      this.onimalId = this.data.id;
      console.log("id animal",this.onimalId);
      
      this.animalForm.patchValue({
        name: this.data.name,
        espece: this.data.espece,
        race: this.data.race,
        age: this.data.age,
        sexe: this.data.sexe,
        allergies: this.data.allergies,
        antecedentsMedicaux: this.data.antecedentsMedicaux,
        ownerId: this.data.ownerId


      });
    }
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
      const payload = {
        updatedanimal: this.animalForm.value
      };
      console.log('Sending payload:', payload);
  
      const response = this.animalService.UpdateAnimal(payload, this.onimalId)
  
  
      console.log('Animal modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'Animal modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification de l\'animal:', error);
  
      let errorMessage = 'Une erreur est survenue lors de la modification.';
      
      // Handle different error formats
      if (error?.error?.message) {
        errorMessage = error.error.message;
      } else if (error?.message) {
        errorMessage = error.message;
      }
  
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



