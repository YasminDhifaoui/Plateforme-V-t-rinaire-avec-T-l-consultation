namespace backend.Dtos.VetDtos.VetAuthDtos
{
    public class VetResetPasswordDto
    {
        public string Email { get; set; } = string.Empty;

        public string NewPassword { get; set; } = string.Empty;
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
