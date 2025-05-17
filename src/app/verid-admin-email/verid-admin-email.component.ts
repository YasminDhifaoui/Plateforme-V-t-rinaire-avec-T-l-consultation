import { Component } from '@angular/core';
import { AdminAuthService } from '../services/admin-auth.service';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-verid-admin-email',
  imports: [FormsModule,CommonModule],
  templateUrl: './verid-admin-email.component.html',
  styleUrl: './verid-admin-email.component.css'
})
export class VeridAdminEmailComponent {
  formData = {
    email: '',
    code: ''
  };
  errorMessage: string = '';

  constructor(private authService: AdminAuthService, private router: Router) {}

  verifyCode() {
    this.authService.verifyAdminCode(this.formData).subscribe({
      next: (res) => {
        // Stocke le token
        localStorage.setItem('authToken', res.token);
        this.router.navigate(['/login']);
      },
      error: (err) => {
        this.errorMessage = err.error?.message || 'Code ou email incorrect.';
      }
    });
  }
}
