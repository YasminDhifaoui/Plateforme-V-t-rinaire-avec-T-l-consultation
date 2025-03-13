using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System;

namespace backend.Models
{
    public class Paiement
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public decimal Montant { get; set; }

        [Required, MaxLength(50)]
        public string Methode { get; set; }

        public PaiementStatus Status { get; set; } = PaiementStatus.EnAttente;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("Commande")]
        public Guid CommandeId { get; set; }
        public Commande Commande { get; set; }
    }

    public enum PaiementStatus
    {
        Réussi,
        Échoué,
        EnAttente
    }
}


