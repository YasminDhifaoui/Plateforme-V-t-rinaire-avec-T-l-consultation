import { TestBed } from '@angular/core/testing';

import { VeterinaireService } from './veterinaire.service';

describe('VeterinaireService', () => {
  let service: VeterinaireService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(VeterinaireService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
