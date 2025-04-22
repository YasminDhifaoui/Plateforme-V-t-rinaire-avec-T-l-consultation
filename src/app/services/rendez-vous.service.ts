import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
@Injectable({
  providedIn: 'root'
})
export class RendezVousService {

  url = 'https://localhost:7000/api/admin/Rendez_vous'
  constructor(private http: HttpClient) { }

  getAllrendezvous(){
   return this.http.get(this.url+ '/get-all-rendez-vous');
  }
  Addrendezvous(client: any) :Observable<any> {
    return this.http.post(this.url + '/add-rendez-vous' , client)
  }
  Deleterendezvous(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-rendez-vous/' +id)
  }
  Updaterendezvous(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-rendez-vous/' + id , client)
  }
  getrendezvousById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-rendez-vous-by-id/' +id)
  }
  
}


