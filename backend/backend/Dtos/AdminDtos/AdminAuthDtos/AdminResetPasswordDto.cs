namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class AdminResetPasswordDto
    {
        public string NewPassword { get; set; } = string.Empty;     
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
