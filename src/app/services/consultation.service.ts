import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ConsultationService {

  url = 'http://localhost:5000/api/admin/Consultation'
  constructor(private http: HttpClient) { }

  getAllconsultations(){
   return this.http.get(this.url+ '/get-all-consultations');
  }

  getConsultationsToday() {
    return this.http.get(this.url + '/get-consultations-today');
  }
  Addconsultations(formData: any) :Observable<any> {
    return this.http.post(this.url + '/add-consultation' , formData)
  }
  Deleteconsultations(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-consultation/' +id)
  }
  Updateconsultations(consultation: any, id: string): Observable<any> {
    const token = localStorage.getItem('token');
    const formData = new FormData();
  
    // Append all fields to formData
    Object.keys(consultation).forEach(key => {
      if (consultation[key] !== null && consultation[key] !== undefined) {
        formData.append(key, consultation[key]);
      }
    });
  
    return this.http.put(
      `${this.url}/update-consultation/${id}`,
      formData,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          // Don't set Content-Type - let browser set it with boundary
        }
      }
    );
  }
  getconsultations (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-consultation-by-id/' +id)
  }
 
 
  
}
