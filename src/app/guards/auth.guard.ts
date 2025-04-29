import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router); // pour utiliser Router dans une fonction

  const token = localStorage.getItem('token'); // récupère le token

  if (token) {
    // Si le token existe, accès autorisé
    return true;
  } else {
    // Sinon, redirection vers login
    router.navigate(['/login']);
    return false;
  }
};
