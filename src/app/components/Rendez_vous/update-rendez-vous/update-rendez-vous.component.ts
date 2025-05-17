import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { ClientService } from '../../../services/client.service';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { RendezVousService } from '../../../services/rendez-vous.service';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { VeterinaireService } from '../../../services/veterinaire.service';
import { AnimalService } from '../../../animal.service';

@Component({
  selector: 'app-update-rendez-vous',
  imports: [ CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    
    MatFormFieldModule,
    MatInputModule,
    MatDatepickerModule,
    MatNativeDateModule
    ],
  templateUrl: './update-rendez-vous.component.html',
  styleUrl: './update-rendez-vous.component.css'
})
export class UpdateRendezVousComponent {

  rendezvousForm: FormGroup;
  rendezvousId: any;
  veterinare: any [] = [];
  clients: any [] = [];
  animal: any [] = [];


  constructor(
    public dialogRef: MatDialogRef<UpdateRendezVousComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private rendezvousService: RendezVousService,
    private verterinareServcie: VeterinaireService,
    private ClientService: ClientService,
    private animalService: AnimalService,
  ) {
    this.rendezvousForm = this.fb.group({
      vetId: [''],
      clientId: [''],
      animalId: [''],
      date: [''],
      status: ['']
      
    });
  }
  loadveterinare(): void {
    this.verterinareServcie.getAllVeterinaires().subscribe({
      next: (data) => {
        console.log('Vétérinaires récupérés:', data);
        this.veterinare = data as any[];
      },
      error: (err) => console.log(err)
    });
  }
  loadClient(): void {
    this.ClientService.getAllClients().subscribe({
      next: (data) => {
        console.log('clients récupérés:', data);
        this.clients = data as any[];
      },
      error: (err) => console.log(err)
    });
  }
  loadAnimal(): void {
    this.animalService.getAllAnimals().subscribe({
      next: (data) => {
        console.log('animals récupérés:', data);
        this.clients = data as any[];
      },
      error: (err) => console.log(err)
    });
  }
  

  ngOnInit(): void {
    if (this.data) {
      console.log(this.data);
      
      this.rendezvousId = this.data.id;
      this.rendezvousForm.patchValue({
        vetId: this.data.vetId,
        clientId: this.data.clientId,
        animalId: this.data.animalId,
        date: this.data.date,
        status: this.data.status

        
      });
    }
  }


  

  async onSubmit(): Promise<void> {
    if (this.rendezvousForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const payload = {
        updatedClient: this.rendezvousForm.value
      };
  
      const response = await firstValueFrom(
        this.rendezvousService.Updaterendezvous(payload, this.rendezvousId)
      );
  
      console.log('rendezvous modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'rendezvous modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du rendezvous:', error);
  
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


