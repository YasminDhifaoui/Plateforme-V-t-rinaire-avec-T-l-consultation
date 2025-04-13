using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class AdminConfirmEmailDto
    {
        [Required]
        public string Email { get; set; } = string.Empty;
        [Required]

        public string Code { get; set; } = string.Empty;
    }
}
