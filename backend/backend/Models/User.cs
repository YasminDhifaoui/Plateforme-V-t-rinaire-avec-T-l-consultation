using backend.Data;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; }

        [Required, MaxLength(50)]
        public string Username { get; set; }

        [Required]
        public string Password { get; set; }

        [Required]
        public string Role { get; set; } 

        public bool TwoFactorEnabled { get; set; } = false; 

        public string? TwoFactorCode { get; set; }  

        public DateTime? TwoFactorExpiration { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        //public List<Animal> Animals { get; set; }
    }
}
