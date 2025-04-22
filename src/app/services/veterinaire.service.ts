import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';



@Injectable({
  providedIn: 'root'
})
export class VeterinaireService {

  url = 'https://localhost:7000/api/admin/Veterinaires';

  constructor(private http: HttpClient) {}

  getAllVeterinaires() {
    return this.http.get(this.url + '/get-all-veterinaires');
  }

  AddVeterinaire(veterinaire: any): Observable<any> {
    return this.http.post(this.url + '/add-veterinaire', veterinaire);
  }

  DeleteVeterinaire(id: any): Observable<any> {
    return this.http.delete(this.url + '/delete-veterinaire/' + id);
  }

  UpdateVeterinaire(veterinaire: any, id: any): Observable<any> {
    return this.http.put(this.url + '/update-veterinaire/' + id, veterinaire);
  }

  getVeterinaireById(id: any): Observable<any> {
    return this.http.get(this.url + '/get-veterinaire-by-id/' + id);
  }

}
