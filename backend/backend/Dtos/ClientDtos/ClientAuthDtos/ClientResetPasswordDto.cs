namespace backend.Dtos.ClientDtos.ClientAuthDtos
{
    public class ClientResetPasswordDto
    {
        public string Email { get; set; }
        public string NewPassword { get; set; }
        public string ConfirmPassword { get; set; }
        public string Token { get; set; }
    }
}
