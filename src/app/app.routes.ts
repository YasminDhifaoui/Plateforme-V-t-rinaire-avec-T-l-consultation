import { Routes } from '@angular/router';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { ClientsComponent } from './components/client/list-client/clients.component';
import { NavbarComponent } from './components/navbar/navbar.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { authGuard } from './auth.guard';
import { CodeVerificationComponent } from './code-verification/code-verification.component';
import { ListVeterinaireComponent } from './components/veterinaire/list-veterinaire/list-veterinaire.component';
import { ListAnimalComponent } from './components/animals/list-animal/list-animal.component';
import { ListRendezVousComponent } from './components/Rendez_vous/list-rendez-vous/list-rendez-vous.component';
export const routes: Routes = [
    {path: 'sidebar' , component: SidebarComponent},
    {path: 'clients' , component: ClientsComponent, canActivate: [authGuard]},
    {path:'veterinaires',component:ListVeterinaireComponent},
    {path: 'navbar', component:NavbarComponent},
    { path: '', redirectTo: 'login', pathMatch: 'full' },
    { path: 'login', component: LoginComponent },
    { path: 'register', component: RegisterComponent },
    { path: 'verif-code', component: CodeVerificationComponent },
    { path: 'animals', component: ListAnimalComponent },
    { path: 'RendezVous', component: ListRendezVousComponent },
    
  
];
