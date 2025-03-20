using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class AppUser : IdentityUser<Guid>
    {
    [Required]
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    public String Role { get; set; }
    public bool TwoFactorEnabled { get; set; } = false;
    public string? TwoFactorCode { get; set; }
    public DateTime? TwoFactorExpiration { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public List<Animal> Animals { get; set; }
        public string CodeConfirmationLogin { get; internal set; }
        public DateTime TokenCreationTime { get; internal set; }
    }
}
