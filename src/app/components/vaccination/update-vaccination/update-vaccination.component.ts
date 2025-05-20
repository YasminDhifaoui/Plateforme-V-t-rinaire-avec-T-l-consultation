import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { VaccinationService } from '../../../services/vaccination.service'; 
import { ReactiveFormsModule } from '@angular/forms';
@Component({
  selector: 'app-update-vaccination',
  imports: [ ReactiveFormsModule
    ],
  templateUrl: './update-vaccination.component.html',
  styleUrls: ['./update-vaccination.component.css']
})
export class UpdateVaccinationComponent implements OnInit {
  vaccinationForm: FormGroup;
  vaccinationId: any;

  constructor(
    public dialogRef: MatDialogRef<UpdateVaccinationComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private vaccinationService: VaccinationService
  ) {
    this.vaccinationForm = this.fb.group({
      name: ['', Validators.required],
      date: ['', Validators.required],
      animalId: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    if (this.data) {
      this.vaccinationId = this.data.id;
      this.vaccinationForm.patchValue({
        name: this.data.name,
        date: this.data.date,
        animalId: this.data.animalId
      });
    }
  }

  async valider(): Promise<void> {
    if (this.vaccinationForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir tous les champs requis.',
        icon: 'error'
      });
      return;
    }

    try {
      await firstValueFrom(
        this.vaccinationService.Updatevaccination(this.vaccinationForm.value, this.vaccinationId)
      );

      await Swal.fire({
        title: 'Succès',
        text: 'Vaccination mise à jour avec succès.',
        icon: 'success'
      });

      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la mise à jour de la vaccination:', error);
      const errorMessage = error?.error?.message || 'Une erreur est survenue.';
      await Swal.fire({
        title: 'Erreur',
        text: errorMessage,
        icon: 'error'
      });
    }
  }

  annuler(): void {
    this.dialogRef.close();
  }
}
