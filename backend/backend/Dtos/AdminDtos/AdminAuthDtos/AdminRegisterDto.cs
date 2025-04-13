using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class AdminRegisterDto
    {
        [Required]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Username { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
    }
}
