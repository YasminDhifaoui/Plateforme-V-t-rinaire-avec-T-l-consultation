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
  


  toggleCollapse(){
    this.collapsed = !this.collapsed
    // lorsque il est ouvert le contenu chnage 
    // this.sharedStateService.changeSidebarState(this.collapsed);
    }
    colseSidenav(){
    this.collapsed = false
    }
}
