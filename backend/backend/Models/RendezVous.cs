using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class RendezVous
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public DateTime Date { get; set; }

        public RendezVousStatus Status { get; set; } = RendezVousStatus.Confirmé;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("Veterinaire")]
        public Guid VeterinaireId { get; set; }
        public AppUser Veterinaire { get; set; }

        [ForeignKey("Client")]
        public Guid ClientId { get; set; }
        public AppUser Client { get; set; }

        [ForeignKey("Animal")]
        public Guid AnimalId { get; set; }
        public Animal Animal { get; set; }
    }

    public enum RendezVousStatus
    {
        Confirmé,
        Annulé,
        Terminé
    }
}

