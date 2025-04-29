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
      username: [''],
      email: [''],
      password: ['']
      
    });
  }

  ngOnInit(): void {
    if (this.data) {
      console.log(this.data);
      
      this.clientId = this.data.id;
      this.clientForm.patchValue({
        username: this.data.username,
        email: this.data.email,
        password: this.data.password
        
      });
    }
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
      const payload = {
        updatedClient: this.clientForm.value
      };
  
      const response = await firstValueFrom(
        this.clientService.UpdateClient(payload, this.clientId)
      );
  
      console.log('Client modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'Client modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du client:', error);
  
      const errorMessage =
        error?.error?.message || 'Une erreur est survenue lors de la modification.';
  
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
