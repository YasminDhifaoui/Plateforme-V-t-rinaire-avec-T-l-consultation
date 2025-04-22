import { Component } from '@angular/core';
import { Router } from '@angular/router'
import { AdminAuthService } from '../../services/admin-auth.service';
import { MatMenuModule } from '@angular/material/menu'; // Pour mat-menu
import { MatIconModule } from '@angular/material/icon';   // Pour les icônes (facultatif si utilisé)
import { MatButtonModule } from '@angular/material/button'; // Si tu utilises des boutons mat-button

@Component({
  selector: 'app-navbar',
  imports: [MatMenuModule, MatIconModule, MatButtonModule],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.css'
})
export class NavbarComponent {
  constructor(private router: Router, private authService: AdminAuthService) {}

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

}
