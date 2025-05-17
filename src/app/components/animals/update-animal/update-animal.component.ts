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
  
    // Send the form value directly without wrapping in "updatedanimal"
    const payload = this.animalForm.value;
    console.log('Sending payload:', payload);
  
    this.animalService.UpdateAnimal(payload, this.onimalId).subscribe({
      next: async (response) => {
        console.log('Response from server:', response);
        
        // Check if the response contains an error message
        if (response?.message && response.message.includes('not found')) {
          await Swal.fire({
            title: 'Erreur',
            text: response.message,
            icon: 'error'
          });
          return;
        }
  
        await Swal.fire({
          title: 'Succès',
          text: 'Animal modifié avec succès.',
          icon: 'success'
        });
  
        this.dialogRef.close(true);
      },
      error: async (error) => {
        console.error('Erreur lors de la modification de l\'animal:', error);
        
        let errorMessage = 'Une erreur est survenue lors de la modification.';
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
    });
  }
  

  annuler(): void {
    this.dialogRef.close()
  }
}



