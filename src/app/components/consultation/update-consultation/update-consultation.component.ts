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
import { ConsultationService } from '../../../services/consultation.service';
import { MatOptionModule } from '@angular/material/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
@Component({
  selector: 'app-update-consultation',
  imports: [CommonModule,
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
    MatIconModule],
  templateUrl: './update-consultation.component.html',
  styleUrl: './update-consultation.component.css'
})
export class UpdateConsultationComponent implements OnInit{
  consultationForm: FormGroup;
  consultationId: any;
  rendezVous: any [] = [];
  selectedFile: File | null = null;

  constructor(
    public dialogRef: MatDialogRef<UpdateConsultationComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: FormBuilder,
    private rendezvousService: RendezVousService,
    private ConsultationService : ConsultationService,
    
    private animalService: AnimalService,
  ) {
    this.consultationForm = this.fb.group({
      date: ['', Validators.required], 
      Diagnostic: ['', Validators.required],
      Treatment: ['', Validators.required],
      Prescription: ['', Validators.required],
      Notes: ['', Validators.required],
      Document: ['', Validators.required],
      rendezVousID: ['', Validators.required]
    });
  }
 

 

  ngOnInit(): void {
    this.loadRendezVous();
    if (this.data) {
      console.log(this.data);
      
      this.consultationId = this.data.id;
      this.consultationForm.patchValue({
        date: this.data.date,
        Diagnostic: this.data.Diagnostic,
        Treatment: this.data.Treatment,
        Prescription: this.data.Prescription,
        Notes: this.data.Notes,
        Document: this.data.Document,
        rendezVousID: this.data.rendezVousID

        
      });
    }
  }

  
  loadRendezVous(): void {
    this.rendezvousService.getAllrendezvous().subscribe({
      next: (data) => {
        console.log('Rendez-vous récupérés:', data);
        this.rendezVous = data as any[];
      },
      error: (err) => console.error(err)
    });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
    }
  }

  async onSubmit(): Promise<void> {
    if (this.consultationForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const payload = {
        updatedrendezvousId: this.consultationForm.value
      };
  
      const response = await firstValueFrom(
        this.ConsultationService.Updateconsultations(payload, this.consultationId)
      );
  
      console.log('consultation modifié avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: 'consultation modifié avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du consultation:', error);
  
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





