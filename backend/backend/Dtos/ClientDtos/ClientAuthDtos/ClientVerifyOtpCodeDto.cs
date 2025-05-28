using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.ClientDtos.ClientAuthDtos
{
    public class ClientVerifyOtpCodeDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [StringLength(6, MinimumLength = 6, ErrorMessage = "OTP Code must be 6 digits.")]
        public string OtpCode { get; set; }
    }

}
