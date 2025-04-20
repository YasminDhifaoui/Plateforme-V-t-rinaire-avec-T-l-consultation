namespace backend.Dtos.ClientDtos.ProfileDtos
{
    public class ClientProfileDto
    {

        public string? UserName { get; set; }
        public string Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }
        public string? Address { get; set; }
        public string? ZipCode { get; set; }
        public string Gender { get; set; }

        public List<string> AnimalNames { get; set; } = new();
    }

}
