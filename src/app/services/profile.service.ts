import { HttpClient,HttpHeaders  } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ProfileService {

  url = 'http://localhost:5000/api/admin/profile'
  constructor(private http: HttpClient) { }

  seeprofile() {
    const headers = new HttpHeaders({
      'Authorization': `Bearer ${localStorage.getItem('authToken')}`
    });
    return this.http.get(this.url + '/see-profile', { headers });
  }
  
  updateprofile(client: any): Observable<any> {
    const headers = new HttpHeaders({
      'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      'Content-Type': 'application/json'
    });
    
    return this.http.put(
      `${this.url}/update-profile`,
      client,
      { headers }
    );
  }
  
}
