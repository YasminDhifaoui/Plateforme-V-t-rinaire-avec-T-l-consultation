using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.ClientDtos.ClientAuthDtos
{
    public class ClientChangePasswordDto
    {
        [Required]
        public string CurrentPassword { get; set; }
        [Required]

        public string NewPassword { get; set; }
        [Required]
        [Compare("NewPassword")]
        public string ConfirmPassword { get; set; }
    }
}
