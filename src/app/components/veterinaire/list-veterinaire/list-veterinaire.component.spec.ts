import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ListVeterinaireComponent } from './list-veterinaire.component';

describe('ListVeterinaireComponent', () => {
  let component: ListVeterinaireComponent;
  let fixture: ComponentFixture<ListVeterinaireComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ListVeterinaireComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ListVeterinaireComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
