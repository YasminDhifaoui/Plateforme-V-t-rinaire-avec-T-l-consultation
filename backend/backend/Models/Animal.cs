using backend.Data;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Animal
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required, MaxLength(100)]
        public string Nom { get; set; } = string.Empty;

        [Required, MaxLength(50)]
        public string Espece { get; set; } = string.Empty ;

        [MaxLength(50)]
        public string Race { get; set; } =string.Empty ;

        public int Age { get; set; }

        [Required]
        public string Sexe { get; set; } = string.Empty;

        public string Allergies { get; set; } = string.Empty;
        public string AnttecedentsMedicaux { get; set; } = string.Empty;


        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<Vaccination> Vaccinations { get; set; } = new List<Vaccination>();

        [ForeignKey("AppUser")]
        public Guid OwnerId { get; set; }
        public AppUser Owner { get; set; } = null!;

    }

}
