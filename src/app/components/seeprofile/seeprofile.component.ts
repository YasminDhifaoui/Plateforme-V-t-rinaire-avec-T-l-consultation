import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ProfileService } from '../../services/profile.service';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-seeprofile',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatProgressSpinnerModule // Ajout de l'import pour mat-spinner
  ],
  templateUrl: './seeprofile.component.html',
  styleUrls: ['./seeprofile.component.css']
})
export class SeeprofileComponent implements OnInit {
 profileForm: FormGroup;
  profileData: any;
  isEditing = false;
  isLoading = false;
  isSubmitting = false;
  errorMessage: string | null = null;

  constructor(
    private profileService: ProfileService,
    private fb: FormBuilder,
    private snackBar: MatSnackBar
  ) {
    this.profileForm = this.fb.group({
      userName: [''],
      email: ['', [Validators.required, Validators.email]],
      phoneNumber: [''],
      firstName: [''],
      lastName: [''],
      birthDate: [''],
      address: [''],
      zipCode: [''],
      gender: ['']
    });
  }

  ngOnInit(): void {
    this.loadProfile();
  }

  loadProfile(): void {
    this.isLoading = true;
    this.errorMessage = null;

    this.profileService.seeprofile().subscribe({
      next: (data) => {
        this.profileData = data;
        this.profileForm.patchValue(data);
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Failed to load profile data';
        console.error('Error loading profile:', err);
        this.isLoading = false;
      }
    });
  }

  toggleEdit(): void {
    this.isEditing = !this.isEditing;
    if (!this.isEditing) {
      this.profileForm.patchValue(this.profileData);
    }
  }

  onSubmit(): void {
    if (this.profileForm.valid) {
      this.isSubmitting = true;
      this.errorMessage = null;

      this.profileService.updateprofile(this.profileForm.value).subscribe({
        next: (response) => {
          this.snackBar.open('Profile updated successfully!', 'Close', {
            duration: 3000
          });
          this.profileData = { ...this.profileData, ...this.profileForm.value };
          this.isEditing = false;
          this.isSubmitting = false;
        },
        error: (err) => {
          this.snackBar.open('Error updating profile', 'Close', {
            duration: 3000,
            panelClass: ['error-snackbar']
          });
          console.error('Error updating profile:', err);
          this.isSubmitting = false;
        }
      });
    }
  }
}