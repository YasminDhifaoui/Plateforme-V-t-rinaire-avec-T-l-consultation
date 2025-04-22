import { CanActivateFn } from '@angular/router';
import { AdminAuthService } from './services/admin-auth.service';
import { inject } from '@angular/core';                
import { Router } from '@angular/router'; 


export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AdminAuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  } else {
    router.navigate(['/login']);
    return false;
  }
};
