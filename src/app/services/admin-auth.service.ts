import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';



@Injectable({
  providedIn: 'root'
})
export class AdminAuthService {
  private baseUrl = 'http://localhost:5000/api/AdminAuthentification';

  constructor(private http: HttpClient) { }
  login(data: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/login`, data);
  }

  register(data: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/register`, data);
  }
  verifyLoginCode(data: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/verify-login-code`, data);
  }
  verifyAdminCode(data: any): Observable<any> {
    return this.http.post(
      `${this.baseUrl}/confirm-admin-email?email=${encodeURIComponent(data.email)}&code=${encodeURIComponent(data.code)}`,
      null 
    );
  }
  
  logout() {
    localStorage.removeItem('authToken');
  }

  isAuthenticated(): boolean {
    return !!localStorage.getItem('authToken');
  }
 
  
}
