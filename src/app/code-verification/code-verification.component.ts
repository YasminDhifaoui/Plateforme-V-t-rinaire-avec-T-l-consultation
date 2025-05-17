import { Component } from '@angular/core';
import { AdminAuthService } from '../services/admin-auth.service';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-code-verification',
  imports: [CommonModule,FormsModule],
  templateUrl: './code-verification.component.html',
  styleUrl: './code-verification.component.css'
})
export class CodeVerificationComponent {
  formData = {
    email: '',
    code: ''
  };
  errorMessage: string = '';

  constructor(private authService: AdminAuthService, private router: Router) {}

  verifyCode() {
    this.authService.verifyLoginCode(this.formData).subscribe({
      next: (res) => {
        // Stocke le token
        localStorage.setItem('authToken', res.token);
        this.router.navigate(['/sidebar']);
      },
      error: (err) => {
        this.errorMessage = err.error?.message || 'Code ou email incorrect.';
      }
    });
  }
  
}