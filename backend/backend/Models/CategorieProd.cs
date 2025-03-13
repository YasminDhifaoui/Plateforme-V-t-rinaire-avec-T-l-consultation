using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class CategorieProd
    {
        [Required]
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string Libele { get; set; }


        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<Produit> Produits { get; set; }
    }
}
