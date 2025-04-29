import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpdatecompteComponent } from './updatecompte.component';

describe('UpdatecompteComponent', () => {
  let component: UpdatecompteComponent;
  let fixture: ComponentFixture<UpdatecompteComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UpdatecompteComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpdatecompteComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
