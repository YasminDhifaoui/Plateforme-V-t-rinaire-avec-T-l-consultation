import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VeridAdminEmailComponent } from './verid-admin-email.component';

describe('VeridAdminEmailComponent', () => {
  let component: VeridAdminEmailComponent;
  let fixture: ComponentFixture<VeridAdminEmailComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VeridAdminEmailComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(VeridAdminEmailComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
