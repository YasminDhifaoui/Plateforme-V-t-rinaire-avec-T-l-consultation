import { Component, OnInit, ViewChild } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { ProductService } from '../../../services/product.service';
import { AddProductComponent } from './add-product/add-product.component';
import { UpdateProductComponent } from './update-product/update-product.component';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-list-product',
  imports: [
    MatInputModule,
    MatTableModule,
    MatPaginatorModule,
    CommonModule,
    MatIconModule,
    FormsModule,
    RouterModule,
    MatCardModule,
    MatFormFieldModule
  ],
  templateUrl: './list-product.component.html',
  styleUrl: './list-product.component.css'
})
export class ListProductComponent implements OnInit {
  constructor(private dialog: MatDialog, private productService: ProductService, private router: Router) {}

  displayedColumns: string[] = ['name', 'imageUrl', 'description', 'price', 'available', 'actions'];
  dataSource = new MatTableDataSource<Product>();

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  ngOnInit(): void {
    this.productService.getAllProducts().subscribe(
      (res: any) => {
        if (Array.isArray(res)) {
          this.dataSource.data = res as Product[];
        } else {
          console.error('Unexpected data format:', res);
        }
      }
    );
  }

  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
  }

  applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  openAddProductDialog() {
    const dialogRef = this.dialog.open(AddProductComponent, {
      width: '400px',
      ariaDescribedBy: 'add-product-description'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('New product:', result);
        this.ngOnInit();
      }
    });
  }

  openUpdateProductDialog(product: any) {
    const dialogRef = this.dialog.open(UpdateProductComponent, {
      width: '400px',
      ariaDescribedBy: 'update-product-description',
      data: product
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.productService.getAllProducts().subscribe(
          (res: any) => {
            if (Array.isArray(res)) {
              this.dataSource.data = res as Product[];
              this.ngOnInit();
            }
          }
        );
      }
    });
  }

 deleteProduct(id: any) {
  Swal.fire({
    title: 'Are you sure?',
    text: 'This action cannot be undone!',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#3085d6',
    cancelButtonColor: '#d33',
    confirmButtonText: 'Yes, delete it!',
    cancelButtonText: 'Cancel'
  }).then((result) => {
    if (result.isConfirmed) {
      this.productService.deleteProduct(id).subscribe({
        next: (res) => {
          if (res === 'Product deleted successfully.') {
            this.dataSource.data = this.dataSource.data.filter(product => product.id !== id);
            Swal.fire({
              title: 'Deleted!',
              text: res,
              icon: 'success',
              confirmButtonText: 'OK'
            });
          } else {
            Swal.fire({
              title: 'Error',
              text: res,
              icon: 'error',
              confirmButtonText: 'OK'
            });
          }
        },
        error: (err) => {
          console.error('Error deleting product:', err);
          Swal.fire({
            title: 'Error',
            text: 'An error occurred while deleting the product. Please try again.',
            icon: 'error',
            confirmButtonText: 'OK'
          });
        }
      });
    }
  });
 }}

export interface Product {
  id: string;
  name: string;
  imageUrl: string;
  description: string;
  price: number;
  available: number;
}