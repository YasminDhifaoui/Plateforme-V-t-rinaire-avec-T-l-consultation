using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Produit
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid(); 

        [Required, MaxLength(100)]
        public string NomProduit { get; set; }

        public string Description { get; set; }

        [Required]
        public decimal Price { get; set; } 

        [Required]
        public int Stock { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;


        [ForeignKey("CategorieProd")]
        public Guid CategorieId { get; set; }
        public CategorieProd Categorie { get; set; }
    }
}
