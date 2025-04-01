namespace backend.Dtos.VetDtos.VetAuthDtos
{
    public class VetResetPasswordDto
    {
        public string Email { get; set; }
        public string NewPassword { get; set; }
        public string ConfirmPassword { get; set; }
        public string Token { get; set; }
    }
}
