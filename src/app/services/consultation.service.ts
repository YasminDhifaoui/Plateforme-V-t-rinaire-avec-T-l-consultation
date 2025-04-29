import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ConsultationService {

  url = 'https://localhost:7000/api/admin/Consultation'
  constructor(private http: HttpClient) { }

  getAllconsultations(){
   return this.http.get(this.url+ '/get-all-consultations');
  }
  Addconsultations(formData: any) :Observable<any> {
    return this.http.post(this.url + '/add-consultation' , formData)
  }
  Deleteconsultations(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-consultation/' +id)
  }
  Updateconsultations(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-consultation/' + id , client)
  }
  getconsultations (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-consultation-by-id/' +id)
  }
 
  
}
