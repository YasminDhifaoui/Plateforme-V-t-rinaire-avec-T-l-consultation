namespace backend.Dtos.VetDtos.VetAuthDtos
{
    public class VetResetPasswordDto
    {
        public string NewPassword { get; set; } = string.Empty;
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
