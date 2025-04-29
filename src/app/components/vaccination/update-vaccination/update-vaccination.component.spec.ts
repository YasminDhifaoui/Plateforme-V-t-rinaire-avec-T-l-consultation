import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdateVaccinationComponent } from './update-vaccination.component';

describe('UpdateVaccinationComponent', () => {
  let component: UpdateVaccinationComponent;
  let fixture: ComponentFixture<UpdateVaccinationComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UpdateVaccinationComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpdateVaccinationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
