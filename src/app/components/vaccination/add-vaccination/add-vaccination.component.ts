import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
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
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatOptionModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatButtonModule,
    MatIconModule
  ],
  templateUrl: './add-vaccination.component.html',
  styleUrls: ['./add-vaccination.component.css']
})
export class AddVaccinationComponent implements OnInit {
  vaccinationForm: FormGroup;
  animals: any[] = [];

  constructor(
    public dialogRef: MatDialogRef<AddVaccinationComponent>,
    private fb: FormBuilder,
    private router: Router,
    private animalService: AnimalService,
    private vaccinationService: VaccinationService
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
        console.log('Animaux récupérés:', data);
        this.animals = data as any[];
      },
      error: (err) => console.error('Erreur chargement animaux:', err)
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
      const formData = { ...this.vaccinationForm.value };
      formData.date = new Date(formData.date).toISOString();
      console.log('Form Data:', formData);

      const response = await firstValueFrom(this.vaccinationService.Addvaccination(formData));
      console.log('Vaccination ajoutée avec succès !', response);

      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Vaccination ajoutée avec succès.',
        icon: 'success'
      });

      this.dialogRef.close(true); 
    } catch (error: any) {
      console.error('Erreur lors de lajout de la vaccination :', error);

    }
  }

  close(): void {
    this.dialogRef.close(false);
  }
}
