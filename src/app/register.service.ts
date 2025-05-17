import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class RegisterService {
  private baseUrl = 'https://localhost:5000/api/AdminAuthentification';

  constructor(private http: HttpClient) { }

  register(userData: any) {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });
  
    return this.http.post(this.baseUrl + '/register', userData, { headers });
  }
}
