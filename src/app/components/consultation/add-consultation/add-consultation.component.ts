import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
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
import { ConsultationService } from '../../../services/consultation.service';

@Component({
  selector: 'app-add-consultation',
  standalone: true, // Ajouté car tu utilises imports: []
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
  templateUrl: './add-consultation.component.html',
  styleUrls: ['./add-consultation.component.css'] // Correction: style**s**Url → style**s**Urls
})
export class AddConsultationComponent implements OnInit {
  consultationForm: FormGroup;
  rendezVous: any[] = [];
  selectedFile: File | null = null; // Ajouté pour éviter l'erreur

  constructor(
    public dialogRef: MatDialogRef<AddConsultationComponent>,
    private fb: FormBuilder,
    private router: Router,
    private ConsultationService: ConsultationService,
    private RendezVousService: RendezVousService
  ) {
    this.consultationForm = this.fb.group({
      date: ['', Validators.required], // Correction: cohérence avec l'API backend
      Diagnostic: ['', Validators.required],
      Treatment: ['', Validators.required],
      Prescription: ['', Validators.required],
      Notes: ['', Validators.required],
      Document: ['', Validators.required],
      rendezVousID: ['', Validators.required] // Correction : cohérence pour bien matcher dans FormData
    });
  }

  ngOnInit(): void {
    this.loadRendezVous();
  }

  loadRendezVous(): void {
    this.RendezVousService.getAllrendezvous().subscribe({
      next: (data) => {
        console.log('Rendez-vous récupérés:', data);
        this.rendezVous = data as any[];
      },
      error: (err) => console.error(err)
    });
  }

  async onSubmit(): Promise<void> {
    if (!this.consultationForm.value || !this.selectedFile) { // <- meilleure vérification
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs et ajouter un document.',
        icon: 'error'
      });
      return;
    }
  
    try {
      const formData = new FormData();
      const formValues = this.consultationForm.value;
      console.log('Form Values:', formValues);
  
      const formattedDate = new Date(formValues.date).toISOString(); // ISO format (UTC)
formData.append('date', formattedDate);

      formData.append('Diagnostic', formValues.Diagnostic);
      formData.append('Treatment', formValues.Treatment);
      formData.append('Prescription', formValues.Prescription);
      formData.append('Notes', formValues.Notes);
      formData.append('rendezVousID', formValues.rendezVousID);
  
      // Correct : ici on ajoute le vrai fichier
      formData.append('Document', this.selectedFile);
  
      console.log('FormData prêt à être envoyé:', formData);
  
      const response = await firstValueFrom(this.ConsultationService.Addconsultations(formData));
      console.log('Consultation ajoutée avec succès !', response);
  
      await Swal.fire({
        title: 'Succès',
        text: response?.message || 'Consultation ajoutée avec succès.',
        icon: 'success'
      });
  
      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de l’ajout de la Consultation:', error);
  
      await Swal.fire({
        title: 'Erreur',
        text: error?.message || 'Erreur inconnue lors de l’ajout.',
        icon: 'error'
      });
    }
  }
  


  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      console.log('Fichier sélectionné :', this.selectedFile);
    }
  }
  

  close(): void {
    this.dialogRef.close(false);
  }
}
