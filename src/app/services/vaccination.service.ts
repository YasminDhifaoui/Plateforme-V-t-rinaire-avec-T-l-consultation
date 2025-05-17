import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class VaccinationService {

  url = 'http://localhost:5000/api/admin/vaccinations'
  constructor(private http: HttpClient) { }

  getAllvaccination(){
   return this.http.get(this.url+ '/get-all-vaccinations');
  }

  getVaccinationsDueToday() {
    return this.http.get(this.url + '/get-vaccinations-due-today');
  }
  Addvaccination(formData: any) :Observable<any> {
    return this.http.post(this.url + '/add-vaccination' , formData , {
      responseType: 'text' // <--- ignore le parsing JSON
    })
  }
  Deletevaccination(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-vaccination/' +id , {
      responseType: 'text' // <--- ignore le parsing JSON
    })
  }
  Updatevaccination(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-vaccination/' + id , client)
  }
  getvaccinationById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-vaccination-by-id/' +id)
  }
  
}
