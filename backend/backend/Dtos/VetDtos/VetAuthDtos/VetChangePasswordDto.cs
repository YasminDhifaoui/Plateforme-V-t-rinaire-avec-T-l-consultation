using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.VetDtos.VetAuthDtos
{
    public class VetChangePasswordDto
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
