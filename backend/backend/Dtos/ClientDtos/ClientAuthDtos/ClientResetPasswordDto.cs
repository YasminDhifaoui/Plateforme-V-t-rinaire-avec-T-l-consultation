namespace backend.Dtos.ClientDtos.ClientAuthDtos
{
    public class ClientResetPasswordDto 
    {
        public string Email { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
