import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AdminService {

  url = 'https://localhost:7000/api/Admins'
  constructor(private http: HttpClient) { }

  getAlladmins(){
   return this.http.get(this.url+ '/get-all-admins');
  }
  Addadmin(client: any) :Observable<any> {
    return this.http.post(this.url + '/add-admin' , client)
  }
  Deleteadmin(id: any) :Observable<any>{
    return this.http.delete(this.url + '/delete-admin/' +id)
  }
  Updateadmin(client: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-admin/' + id , client)
  }
  getadminById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-admin-by-id/' +id)
  }
  
}
