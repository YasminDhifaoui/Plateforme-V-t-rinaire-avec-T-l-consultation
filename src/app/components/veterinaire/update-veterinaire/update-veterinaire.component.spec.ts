import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdateVeterinaireComponent } from './update-veterinaire.component';

describe('UpdateVeterinaireComponent', () => {
  let component: UpdateVeterinaireComponent;
  let fixture: ComponentFixture<UpdateVeterinaireComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UpdateVeterinaireComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpdateVeterinaireComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
