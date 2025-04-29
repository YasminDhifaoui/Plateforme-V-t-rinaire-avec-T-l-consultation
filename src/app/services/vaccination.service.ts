import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class VaccinationService {

  url = 'https://localhost:7000/api/admin/vaccinations'
  constructor(private http: HttpClient) { }

  getAllvaccination(){
   return this.http.get(this.url+ '/get-all-vaccinations');
  }
  Addvaccination(formData: any) :Observable<any> {
    return this.http.post(this.url + '/add-vaccination' , formData)
  }
  Deletevaccination(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-vaccination/' +id)
  }
  Updatevaccination(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-vaccination/' + id , client)
  }
  getvaccinationById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-vaccination-by-id/' +id)
  }
  
}
