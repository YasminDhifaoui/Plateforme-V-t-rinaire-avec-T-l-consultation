import { Component, OnInit } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { navbarData } from './nav.data';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [FormsModule, CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.css'
})
export class SidebarComponent {
  constructor( private router: Router){}
  
  userCourant! : string;
  collapsed = false ;
  navData = navbarData  
  

  
  
    colseSidenav(){
    this.collapsed = false
    }
    ngOnInit() {
      this.updateBodyClass();
    }
    
    toggleCollapse() {
      this.collapsed = !this.collapsed;
      this.updateBodyClass();
    }
    
    updateBodyClass() {
      if (this.collapsed) {
        document.body.classList.add('sidebar-expanded');
      } else {
        document.body.classList.remove('sidebar-expanded');
      }
    }
    
}
