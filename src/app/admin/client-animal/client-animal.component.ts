import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { AnimalService} from '../../animal.service';// adapte le chemin
import { ClientService } from '../../services/client.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-client-animal',
  imports: [CommonModule],
  templateUrl: './client-animal.component.html',
  styleUrls: ['./client-animal.component.css']
})
export class ClientAnimalComponent implements OnInit {
  ownerId!: string;
  animals: any[] = [];
  clientName: string = '';


  constructor(private route: ActivatedRoute, private ClientService: ClientService) {}

  ngOnInit(): void {
    this.ownerId = this.route.snapshot.paramMap.get('id')!;
    this.ClientService.getAnimalByOwner(this.ownerId).subscribe(
      (res: any) => {
        this.animals = res;
      },
      err => {
        console.error('Erreur lors de la récupération des animaux:', err);
      }
    );
  
  this.ClientService.getClientById(this.ownerId).subscribe(
    (client: any) => {
      this.clientName = client.username; // ou client.nom selon ton modèle
    },
    err => {
      console.error('Erreur lors de la récupération du client:', err);
    }
  );
}}
