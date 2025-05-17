import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AdminService {

  url = 'http://localhost:5000/api/Admins'
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
  Updateadmin(payload: any , id: any) :Observable<any>{
    return this.http.put(this.url + '/update-admin/' + id , payload)
  }
  getadminById (id: any) :Observable<any> {
    return this.http.get(this.url + '/get-admin-by-id/' +id)
  }
  
}
