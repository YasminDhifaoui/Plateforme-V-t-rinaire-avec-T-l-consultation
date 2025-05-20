import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { ProductService } from '../../../../services/product.service';  // Adjust path
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';


@Component({
  selector: 'app-add-product',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatDialogModule, // For mat-dialog-title, mat-dialog-content, mat-dialog-actions
    MatButtonModule, // For mat-button, mat-raised-button
    MatFormFieldModule, // For mat-form-field
    MatInputModule // For matInput
  ],
  templateUrl: './add-product.component.html',
  styleUrls: ['./add-product.component.css']
})
export class AddProductComponent {
  productForm: FormGroup;
  selectedFile: File | null = null;

  constructor(
    public dialogRef: MatDialogRef<AddProductComponent>,
    private fb: FormBuilder,
    private router: Router,
    private ProductService: ProductService
  ) {
    this.productForm = this.fb.group({
      NomProduit: ['', Validators.required],
      Description: [''],
      Price: [0, [Validators.required, Validators.min(0)]],
      Available: [0, [Validators.required, Validators.min(0)]],
      ImageUrl: [null, Validators.required]
    });
  }

  onFileSelected(event: any): void {
    this.selectedFile = event.target.files[0];
    if (this.selectedFile) {
      this.productForm.patchValue({ ImageUrl: this.selectedFile.name });
    }
  }

  async onSubmit(): Promise<void> {
    if (this.productForm.invalid || !this.selectedFile) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir tous les champs requis.',
        icon: 'error'
      });
      return;
    }

    const formData = new FormData();
    formData.append('NomProduit', this.productForm.value.NomProduit);
    formData.append('Description', this.productForm.value.Description);
    formData.append('Price', this.productForm.value.Price.toString());
    formData.append('Available', this.productForm.value.Available.toString());
    formData.append('ImageUrl', this.selectedFile);

    try {
      const response: string = await firstValueFrom(this.ProductService.addProduct(formData));
      if (response === 'Product added successfully.') {
        await Swal.fire({
          title: 'Succès',
          text: response,
          icon: 'success'
        });
        this.dialogRef.close(true);
      } else {
        await Swal.fire({
          title: 'Erreur',
          text: response || 'Erreur lors de l\'ajout du produit.',
          icon: 'error'
        });
      }
    } catch (error: any) {
      console.error('Erreur:', error);
      const errorMessage = error.message || 'Erreur lors de l\'ajout du produit.';
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