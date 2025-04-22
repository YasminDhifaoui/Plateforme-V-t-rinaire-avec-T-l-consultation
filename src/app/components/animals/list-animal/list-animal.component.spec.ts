import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ListAnimalComponent } from './list-animal.component';

describe('ListAnimalComponent', () => {
  let component: ListAnimalComponent;
  let fixture: ComponentFixture<ListAnimalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ListAnimalComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ListAnimalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
