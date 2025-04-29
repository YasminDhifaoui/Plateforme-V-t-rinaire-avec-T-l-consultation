import { Component } from '@angular/core';
import { Router, RouterModule, RouterOutlet } from '@angular/router';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { NavbarComponent } from './components/navbar/navbar.component';

import {  OnInit, Renderer2 } from '@angular/core';



@Component({
  selector: 'app-root',
  imports: [RouterOutlet,RouterModule,SidebarComponent ,NavbarComponent,FormsModule ,CommonModule ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  shownavbar = true;
  showSidebar = true;

  // Liste des routes où la navbar et sidebar ne doivent PAS s'afficher
  private hiddenRoutes: string[] = ['/login', '/register', '/verif-code'];

  constructor(private router: Router, private renderer: Renderer2) {
    this.router.events.subscribe(() => {
      const currentRoute = this.router.url;
      this.shownavbar = !this.hiddenRoutes.includes(currentRoute);
      this.showSidebar = !this.hiddenRoutes.includes(currentRoute);
    });
  }

  ngOnInit(): void {
    const appRoot = document.querySelector('app-root');
    if (appRoot && appRoot.hasAttribute('aria-hidden')) {
      this.renderer.removeAttribute(appRoot, 'aria-hidden');
    }
  }
}

