using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Client
    {
        public Guid ClientId { get; set; } = Guid.NewGuid();

        [ForeignKey("AppUser")]
        public Guid AppUserId { get; set; }
    }
}
