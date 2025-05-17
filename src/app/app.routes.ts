import { Routes } from '@angular/router';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { ClientsComponent } from './components/client/list-client/clients.component';
import { AdminDashboardComponent } from './components/admin-dashboard/admin-dashboard.component';
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { authGuard } from './auth.guard';
import { CodeVerificationComponent } from './code-verification/code-verification.component';
import { ListVeterinaireComponent } from './components/veterinaire/list-veterinaire/list-veterinaire.component';
import { ListAnimalComponent } from './components/animals/list-animal/list-animal.component';
import { ListRendezVousComponent } from './components/Rendez_vous/list-rendez-vous/list-rendez-vous.component';
import { ListAdminComponent } from './components/admins/list-admin/list-admin.component';
import { NavbarComponent } from './components/navbar/navbar.component';
import { SeeprofileComponent } from './components/seeprofile/seeprofile.component';
import { ListConsultationComponent } from './components/consultation/list-consultation/list-consultation.component';
import { AddVaccinationComponent } from './components/vaccination/add-vaccination/add-vaccination.component';
import { ListVaccinationComponent } from './components/vaccination/list-vaccination/list-vaccination.component';
import { VeridAdminEmailComponent } from './verid-admin-email/verid-admin-email.component';
import { ConsultationVeterinaireComponent } from './admin/consultation-veterinaire/consultation-veterinaire.component';
import { ClientAnimalComponent } from './admin/client-animal/client-animal.component';
export const routes: Routes = [
    {path: 'sidebar' , component: SidebarComponent , canActivate: [authGuard]},
    {path: 'navbar' , component: NavbarComponent ,canActivate: [authGuard]},
    {path: 'clients' , component: ClientsComponent, canActivate: [authGuard]},
    {path:'veterinaires',component:ListVeterinaireComponent,canActivate: [authGuard]},
    {path:'admins',component:ListAdminComponent ,canActivate: [authGuard]},
    { path: '', redirectTo: 'login', pathMatch: 'full' },
    { path: 'login', component: LoginComponent },
    { path: 'register', component: RegisterComponent },
    { path: 'verif-code', component: CodeVerificationComponent },
    { path: 'animals', component: ListAnimalComponent ,canActivate: [authGuard]},
    { path: 'RendezVous', component: ListRendezVousComponent ,canActivate: [authGuard]},
    { path: 'consultation', component: ListConsultationComponent,canActivate: [authGuard] },
    { path: 'vaccination', component: ListVaccinationComponent ,canActivate: [authGuard]},
    { path: 'profile', component: SeeprofileComponent ,canActivate: [authGuard]},
    { path: 'verif-admin-email', component: VeridAdminEmailComponent  },
    { path: 'admin-dashboard', component: AdminDashboardComponent ,canActivate: [authGuard]},
    { path: 'consultations-veterinaire/:id', component: ConsultationVeterinaireComponent ,canActivate: [authGuard]},
    { path: 'client-animal/:id', component: ClientAnimalComponent ,canActivate: [authGuard]}
  
];
