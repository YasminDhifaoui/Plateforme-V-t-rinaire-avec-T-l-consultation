import { Component } from '@angular/core';
import { AdminAuthService } from '../../services/admin-auth.service';
import { Router } from '@angular/router'
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
@Component({
  selector: 'app-login',
  imports: [FormsModule,CommonModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  email: string = '';
  password: string = '';
  errorMessage: string = '';
  constructor(private authService: AdminAuthService, private router: Router) {}

  connected() {
    const user = { email: this.email, password: this.password };
    this.authService.login(user).subscribe({
      next: (res) => {
        this.router.navigate(['/verif-code']);
      },
      error: (err) => {
        this.errorMessage = err.error?.error || 'Une erreur est survenue.';
      },
    });
  }
  reset() {
    this.errorMessage = '';
  }

}
