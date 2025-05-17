import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ClientAnimalComponent } from './client-animal.component';

describe('ClientAnimalComponent', () => {
  let component: ClientAnimalComponent;
  let fixture: ComponentFixture<ClientAnimalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ClientAnimalComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ClientAnimalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
