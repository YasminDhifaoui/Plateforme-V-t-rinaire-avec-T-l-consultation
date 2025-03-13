using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Commande
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Decimal Total { get; set; }

        [Required]
        public string AdresseLivraison { get; set; }

        public CommandeStatus Status { get; set; } = CommandeStatus.EnCours;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("Client")]
        public Guid ClientId { get; set; }
        public AppUser Client { get; set; }

        public List<Produit> Produits { get; set; }
    }

    public enum CommandeStatus
    {
        EnCours,
        Expédiée,
        Livrée,
        Annulée
    }
}

