import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';



@Injectable({
  providedIn: 'root'
})
export class VeterinaireService {

  url = 'http://localhost:5000/api/admin/Veterinaires';
  urlv='http://localhost:5000/api/admin/Consultation';

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
    return this.http.get(this.url + '/get-vet-by-id/' + id);
  }
  getconsultationByVet (idvet: any) :Observable<any> {
    return this.http.get(this.urlv + '/get-consultations-by-veterinaire/' +idvet)
  }

}
