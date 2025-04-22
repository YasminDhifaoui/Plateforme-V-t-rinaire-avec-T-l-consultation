import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule, MatLabel } from '@angular/material/form-field';
import { Router } from '@angular/router';
import { MatInputModule } from '@angular/material/input';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { ClientService } from '../../../services/client.service';

@Component({
  selector: 'app-add-client',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,

    MatFormFieldModule,
  ],  templateUrl: './add-client.component.html',
  styleUrl: './add-client.component.css'
})
export class AddClientComponent {
  clientForm: FormGroup;
  

  constructor(
    public dialogRef: MatDialogRef<AddClientComponent>,
    private fb: FormBuilder,
    private router: Router,
    private clientService: ClientService
  ) {
    this.clientForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required]],
      password: ['', [Validators.required]],
    });
  }
  async onSubmit(): Promise<void> {
    if (this.clientForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const formData = this.clientForm.value;
      console.log('Form Data:', formData);
  
      const response = await firstValueFrom(this.clientService.AddClient(formData));
      console.log('Client ajouté avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Client ajouté avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout du client:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de l’ajout du client.';
  
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
