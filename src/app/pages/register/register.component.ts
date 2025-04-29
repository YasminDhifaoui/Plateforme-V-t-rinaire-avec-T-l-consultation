import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RegisterService } from '../../register.service';
import { AdminAuthService } from '../../services/admin-auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './register.component.html',
  styleUrl: './register.component.css'
})
export class RegisterComponent {
  username: string = '';
  email: string = '';
  password: string = '';
  errorMessage: string = '';
  successMessage: string = '';

  constructor(private registerService: AdminAuthService, private router: Router) { }

  register() {
    const data = {
      email: this.email,
      username: this.username,
      password: this.password
    };
    console.log(data);

    this.registerService.register(data).subscribe(
      res => {
        console.log(res);
        this.router.navigate(['/verif-admin-email'])
      },
      err => {
        console.log(err);

      }
    )
  }
}
