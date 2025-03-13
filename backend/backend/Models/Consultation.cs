using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System;

namespace backend.Models
{
    public class Consultation
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public DateTime Date { get; set; }

        [Required, MaxLength(500)]
        public string Diagnostic { get; set; }

        [MaxLength(1000)]
        public string Treatment { get; set; }

        [MaxLength(1000)]
        public string Prescriptions { get; set; }

        [MaxLength(1000)]
        public string Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("RendezVous")]
        public Guid RendezVousId { get; set; }
        public RendezVous RendezVous { get; set; }

        [ForeignKey("Veterinaire")]
        public Guid VeterinaireId { get; set; }
        public AppUser Veterinaire { get; set; }

        [ForeignKey("Animal")]
        public Guid AnimalId { get; set; }
        public Animal Animal { get; set; }
    }
}

