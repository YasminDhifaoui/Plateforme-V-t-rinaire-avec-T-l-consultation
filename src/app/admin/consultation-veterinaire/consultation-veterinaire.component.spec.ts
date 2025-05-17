import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ConsultationVeterinaireComponent } from './consultation-veterinaire.component';

describe('ConsultationVeterinaireComponent', () => {
  let component: ConsultationVeterinaireComponent;
  let fixture: ComponentFixture<ConsultationVeterinaireComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ConsultationVeterinaireComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ConsultationVeterinaireComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
