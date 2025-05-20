import { Component, Inject, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { CommonModule } from '@angular/common';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatButtonModule } from '@angular/material/button';
import Swal from 'sweetalert2';
import { firstValueFrom } from 'rxjs';
import { ProductService } from '../../../../services/product.service'; 
import { Product } from '../list-product.component'; // Import Product from list component

@Component({
  selector: 'app-update-product',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatInputModule,
    MatFormFieldModule,
    MatButtonModule,
    MatDialogModule // Added to support mat-dialog-actions, mat-dialog-title, mat-dialog-content
  ],
  templateUrl: './update-product.component.html',
  styleUrls: ['./update-product.component.css']
})
export class UpdateProductComponent implements OnInit {
  productForm: FormGroup;
  productId: string;

  constructor(
    public dialogRef: MatDialogRef<UpdateProductComponent>,
    @Inject(MAT_DIALOG_DATA) public data: Product,
    private fb: FormBuilder,
    private productService: ProductService
  ) {
    this.productId = '';
    this.productForm = this.fb.group({
      id: [{ value: '', disabled: true }, Validators.required],
      name: ['', [Validators.required, Validators.minLength(3)]],
      imageUrl: ['', [Validators.required, Validators.pattern(/^\/Uploads\/.*\.(jpg|jpeg|png)$/)]],
      description: ['', [Validators.required, Validators.minLength(10)]],
      price: ['', [Validators.required, Validators.min(0.01)]],
      available: ['', [Validators.required, Validators.min(0)]]
    });
  }

  ngOnInit(): void {
    if (this.data) {
      this.productId = this.data.id;
      this.productForm.patchValue({
        id: this.data.id,
        name: this.data.name,
        imageUrl: this.data.imageUrl,
        description: this.data.description,
        price: this.data.price,
        available: this.data.available
      });
    }
  }

  async valider(): Promise<void> {
    if (this.productForm.invalid) {
      await Swal.fire({
        title: 'Erreur',
        text: 'Veuillez remplir correctement tous les champs obligatoires.',
        icon: 'error'
      });
      return;
    }

    try {
      const updatedProduct: Product = {
        id: this.productId,
        name: this.productForm.get('name')?.value,
        imageUrl: this.productForm.get('imageUrl')?.value,
        description: this.productForm.get('description')?.value,
        price: this.productForm.get('price')?.value,
        available: this.productForm.get('available')?.value
      };

      const response = await firstValueFrom(
        this.productService.updateProduct(Number(this.productId), updatedProduct)
      );

      await Swal.fire({
        title: 'Succès',
        text: 'Produit modifié avec succès.',
        icon: 'success'
      });

      this.dialogRef.close(true);
    } catch (error: any) {
      console.error('Erreur lors de la modification du produit:', error);
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
    this.dialogRef.close();
  }
}