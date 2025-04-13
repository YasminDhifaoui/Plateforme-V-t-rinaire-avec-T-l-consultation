namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class AdminVerifyLoginDto
    {
        public string Email { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}
