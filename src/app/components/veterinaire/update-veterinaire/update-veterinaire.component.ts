import { Component, Inject } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { VeterinaireService } from '../../../services/veterinaire.service';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import {  MAT_DIALOG_DATA } from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';

@Component({
  selector: 'app-update-veterinaire',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
  ],
  templateUrl: './update-veterinaire.component.html',
  styleUrl: './update-veterinaire.component.css'
})
export class UpdateVeterinaireComponent {
  veterinaireForm: FormGroup;
  vetId: any;

  constructor(
    public dialogRef: MatDialogRef<UpdateVeterinaireComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private veterinaireService: VeterinaireService
  ) {
    this.veterinaireForm = this.fb.group({
      username: [''],
      email: [''],
      password: [''],
      phoneNumber: [''],
      role:['']

    });
  }

  ngOnInit(): void {
    if (this.data) {
      console.log(this.data);
      
      this.vetId = this.data.id;
      console.log("veterinaire id:"+this.vetId);
      
      this.veterinaireForm.patchValue({
        username: this.data.username,
        email: this.data.email,
        password: this.data.password,
        phoneNumber: this.data.phoneNumber,
        role: this.data.role
      });
    }
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
      const payload = this.veterinaireForm.value; 
  console.log("payload :"+payload);
  
      const response = await firstValueFrom(
        this.veterinaireService.UpdateVeterinaire(payload, this.vetId)
      );
  
      console.log('Vétérinaire modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'Vétérinaire modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du vétérinaire:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de la modification.';
  
      await Swal.fire({
        title: 'Erreur',
        text: errorMessage,
        icon: 'error'
      });
    }
  }
  
  

  annuler(): void {
    this.dialogRef.close()
  }
}
