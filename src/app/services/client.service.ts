import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ClientService {

  url = 'https://localhost:7000/api/Clients'
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
  UpdateClient(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-client/' + id , client)
  }
  getClientById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-client-by-id/' +id)
  }
  
}
