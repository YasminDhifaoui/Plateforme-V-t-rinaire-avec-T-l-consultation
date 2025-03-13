namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class TwoFactorDto
    {
        public Guid UserId { get; set; }
        public string Email { get; set; }
        public string Code { get; set; }
    }
}
