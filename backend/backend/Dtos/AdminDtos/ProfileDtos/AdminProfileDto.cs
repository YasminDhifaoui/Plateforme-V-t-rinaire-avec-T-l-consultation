﻿namespace backend.Dtos.AdminDtos.ProfileDtos
{
    public class AdminProfileDto
    {
        public string Email { get; set; }
        public string? UserName { get; set; }
        public string? PhoneNumber { get; set; }

        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? Address { get; set; }
        public string? ZipCode { get; set; }
        public string Gender { get; set; }
    }
}
