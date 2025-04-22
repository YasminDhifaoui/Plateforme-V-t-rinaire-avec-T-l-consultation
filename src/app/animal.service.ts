import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AnimalService {

  url = 'https://localhost:7000/api/admin/Animals';

  constructor(private http: HttpClient) {}

  getAllAnimals() {
    return this.http.get(this.url + '/get-all-animals');
  }

  AddAnimal(animal: any): Observable<any> {
    const token = localStorage.getItem('token'); // ou sessionStorage
    const headers = {
      'Authorization': `Bearer ${token}`
    };
  
    return this.http.post(this.url + '/add-animal', animal, { headers });
  }
  

  DeleteAnimal(id: any): Observable<any> {
    return this.http.delete(this.url + '/delete-animal/' + id);
  }

  UpdateAnimal(animal: any, id: any): Observable<any> {
    return this.http.put(this.url + '/update-animal/' + id, animal);
  }

  getAnimalById(id: any): Observable<any> {
    return this.http.get(this.url + '/get-animal-by-id/' + id);
  }
}
