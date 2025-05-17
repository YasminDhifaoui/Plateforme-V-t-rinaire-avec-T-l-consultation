import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ClientService {

  url = 'http://localhost:5000/api/admin/Clients'
  urls='http://localhost:5000/api/admin/Animals'
  constructor(private http: HttpClient) { }

  getAllClients(){
   return this.http.get(this.url+ '/get-all-clients');
  }
  AddClient(client: any) :Observable<any> {
    return this.http.post(this.url + '/add-client' , client)
  }
  DeleteClient(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-client/' +id)
  }
  UpdateClient(client: any, id: any): Observable<any> {
    const token = localStorage.getItem('token');
    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
    
    // Add required fields with default values if not provided
    const payload = {
      ...client,
      role: client.role || 'Client', // Default role
      phoneNumber: client.phoneNumber || '',
      twoFactorEnabled: client.twoFactorEnabled || false,
      lockoutEnabled: client.lockoutEnabled || false,
      emailConfirmed: client.emailConfirmed || false,
      phoneConfirmed: client.phoneConfirmed || false
    };
    
    return this.http.put(this.url + '/update-client/' + id, payload, { headers });
  }
  getClientById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-client-by-id/' +id)
  }
  getAnimalByOwner (id: any) :Observable<any> {
    return this.http.get(this.urls + '/get-animals-by-owner-id/' +id)
  }
 
  
}
