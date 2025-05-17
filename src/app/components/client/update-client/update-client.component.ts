import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { ClientService } from '../../../services/client.service';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';

@Component({
  selector: 'app-update-client',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
  ],
  templateUrl: './update-client.component.html',
  styleUrls: ['./update-client.component.css']
})
export class UpdateClientComponent implements OnInit {
  clientForm: FormGroup;
  clientId: any;

  constructor(
    public dialogRef: MatDialogRef<UpdateClientComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private clientService: ClientService
  ) {
    this.clientForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.minLength(6)]],
      role: ['Client'],
      phoneNumber: [''],
      twoFactorEnabled: [false],
      lockoutEnabled: [false],
      emailConfirmed: [false],
      phoneConfirmed: [false]
    });
  }

  ngOnInit(): void {
    if (this.data) {
      this.clientId = this.data.id;
      this.clientForm.patchValue({
        username: this.data.username,
        email: this.data.email,
        password: this.data.password,
        // Add other fields if available in data
        ...(this.data.role && { role: this.data.role }),
        ...(this.data.phoneNumber && { phoneNumber: this.data.phoneNumber })
        // Add other fields as needed
      });
    }
  }

  async valider(): Promise<void> {
    if (this.clientForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }

    try {
      const response = await firstValueFrom(
        this.clientService.UpdateClient(this.clientForm.value, this.clientId)
      );

      await Swal.fire({
        title: 'Succès',
        text: 'Client modifié avec succès.',
        icon: 'success'
      });

      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du client:', error);
      const errorMessage = error?.error?.message || 
                         'Une erreur est survenue lors de la modification.';
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