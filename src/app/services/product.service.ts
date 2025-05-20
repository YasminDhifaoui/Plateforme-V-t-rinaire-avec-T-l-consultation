import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
@Injectable({
  providedIn: 'root'
})
export class ProductService {

  private baseUrl = 'http://localhost:5000/api/admin/Products'; // change selon ton backend

  constructor(private http: HttpClient) {}

  getAllProducts(): Observable<any> {
    return this.http.get(`${this.baseUrl}/get-all-products`);
  }

 addProduct(product: FormData): Observable<string> {
  return this.http.post(`${this.baseUrl}/add-product`, product, {
    responseType: 'text'
  });
}


  updateProduct(id: number, product: any): Observable<any> {
    return this.http.put(`${this.baseUrl}/update-product/${id}`, product);
  }

  deleteProduct(id: string): Observable<any> {
  return this.http.delete(`${this.baseUrl}/delete-product/${id}`, {
    responseType: 'text'
  });
}
}
