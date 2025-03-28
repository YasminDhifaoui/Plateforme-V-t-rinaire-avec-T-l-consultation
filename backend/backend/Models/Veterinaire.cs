using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Veterinaire
    {
        public Guid VeterinaireId { get; set; } = Guid.NewGuid();

        [ForeignKey("AppUser")]
        public Guid AppUserId { get; set; }
    }
}
