import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule, MatLabel } from '@angular/material/form-field';
import { Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { MatSelectModule } from '@angular/material/select';
import { MatOptionModule } from '@angular/material/core';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatIconModule } from '@angular/material/icon';
import { AnimalService } from '../../../animal.service';
import { VaccinationService } from '../../../services/vaccination.service';


@Component({
  selector: 'app-add-vaccination',
  imports: [ CommonModule,
    ReactiveFormsModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatOptionModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatButtonModule,
    MatIconModule],
  templateUrl: './add-vaccination.component.html',
  styleUrl: './add-vaccination.component.css'
})
export class AddVaccinationComponent {
  vaccinationForm: FormGroup;
  animal: any[] = [];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private vaccinationService: VaccinationService,
    private animalService: AnimalService,
    private dialogRef: MatDialogRef<AddVaccinationComponent>   // <-- ajout ici
  ) {
    this.vaccinationForm = this.fb.group({
      name: ['', Validators.required],
      date: ['', Validators.required],
      animalId: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.loadAnimal();
  }

  loadAnimal(): void {
    this.animalService.getAllAnimals().subscribe({
      next: (data) => {
        console.log('animals récupérés:', data);
        this.animal = data as any[];
      },
      error: (err) => console.log(err)
    });
  }

  async onSubmit(): Promise<void> {
    if (this.vaccinationForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }

    try {
      const formData = this.vaccinationForm.value;
      console.log('Form Data:', formData);

      const response = await firstValueFrom(this.vaccinationService.Addvaccination(formData));
      console.log('Vaccination ajouté avec succès !', response);

      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Vaccination ajouté avec succès.',
        icon: 'success'
      });

      this.dialogRef.close(true);  // <-- utilise bien dialogRef ici
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du vaccination:', error);

      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout du vaccination.';

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


