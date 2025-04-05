namespace backend.Dtos.VetDtos
{
    public class UpdateVetDto
    {
        public string Username { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string Role { get; set; }
        public string PhoneNumber { get; set; }

        public bool TwoFactorEnabled { get; set; }
        public bool LockoutEnabled { get; set; }
        public DateTimeOffset? LockoutEnd { get; set; }

        public bool EmailConfirmed { get; set; }
        public bool PhoneConfirmed { get; set; }

        public DateTime UpdatedAt { get; set; }
    }
}
