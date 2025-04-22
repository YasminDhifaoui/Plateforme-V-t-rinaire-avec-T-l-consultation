import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule, MatLabel } from '@angular/material/form-field';
import { Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { RendezVousService } from '../../../services/rendez-vous.service';
import { MatSelectModule } from '@angular/material/select';
import { MatOptionModule } from '@angular/material/core';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-add-rendez-vous',
  standalone: true,
  imports: [  CommonModule,
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
  templateUrl: './add-rendez-vous.component.html',
  styleUrl: './add-rendez-vous.component.css'
})
export class AddRendezVousComponent {
  rendezVousForm: FormGroup;
  

  constructor(
    public dialogRef: MatDialogRef<AddRendezVousComponent>,
    private fb: FormBuilder,
    private router: Router,
    private RendezVousService:RendezVousService
  ) {
    this.rendezVousForm = this.fb.group({
      vetId: ['', Validators.required],
      clientId: ['', [Validators.required]],
      animalId: ['', [Validators.required]],
      date: ['', [Validators.required]],
      status: ['', [Validators.required]],
    });
  }
  async onSubmit(): Promise<void> {
    if (this.rendezVousForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const formData = this.rendezVousForm.value;
      console.log('Form Data:', formData);
  
      const response = await firstValueFrom(this.RendezVousService.Addrendezvous(formData));
      console.log('RendezVous ajouté avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'RendezVous ajouté avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du RendezVous:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout du RendezVous.';
  
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



