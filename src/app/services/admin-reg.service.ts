import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AdminRegService {

  private baseUrl = 'https://localhost:7000/api/AdminAuthentification';

  constructor(private http: HttpClient) { }
  

  register(data: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/register`, data);
  }
  verifyLoginCode(data: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/verify-login-code`, data);
  }
  logout() {
    localStorage.removeItem('token');
  }

  isAuthenticated(): boolean {
    return !!localStorage.getItem('token');
  }
}
