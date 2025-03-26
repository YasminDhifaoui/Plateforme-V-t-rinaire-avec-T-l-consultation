namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class AdminResetPasswordDto
    {
        public string Email { get; set; }
        public string NewPassword { get; set; }
        public string ConfirmPassword { get; set; }
        public string Token { get; set; }
    }
}
