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

        [MaxLength(1000)]
        public string DocumentPath { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("Veterinaire")]
        public Guid VeterinaireId { get; set; }
        public Veterinaire Veterinaire { get; set; }

        [ForeignKey("Client")]
        public Guid ClientId { get; set; }
        public Client Client { get; set; }
    }
}

