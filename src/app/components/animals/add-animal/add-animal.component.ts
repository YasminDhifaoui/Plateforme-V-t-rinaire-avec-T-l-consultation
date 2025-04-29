import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatOptionModule } from '@angular/material/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { AnimalService } from '../../../animal.service';
import { ClientService } from '../../../services/client.service';

@Component({
  selector: 'app-add-animal',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatOptionModule,
    MatButtonModule,
    MatIconModule
  ],
  templateUrl: './add-animal.component.html',
  styleUrls: ['./add-animal.component.css']
})
export class AddAnimalComponent {
  animalForm: FormGroup;
  clients: any[] = [];

  constructor(
    public dialogRef: MatDialogRef<AddAnimalComponent>,
    private fb: FormBuilder,
    private router: Router,
    private animalService: AnimalService,
    private clientService: ClientService
  ) {
    this.animalForm = this.fb.group({
      name: ['', Validators.required],
      espece: ['', Validators.required],
      race: ['', Validators.required],
      age: ['', Validators.required],
      sexe: ['', Validators.required],
      allergies: ['', Validators.required],
      antecedentsMedicaux: ['', Validators.required],
      ownerId: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.loadClient();
  }

  loadClient(): void {
    this.clientService.getAllClients().subscribe({
      next: (data) => {
        console.log('clients récupérés:', data);
        this.clients = data as any[];
      },
      error: (err) => console.log(err)
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
      console.error('Erreur lors de l’ajout de l’animal:', error);

      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout de l’animal.';

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
