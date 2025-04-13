namespace backend.Dtos.ClientDtos.ClientAuthDtos
{
    public class ClientVerifyLoginDto
    {
        public string Email { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}
