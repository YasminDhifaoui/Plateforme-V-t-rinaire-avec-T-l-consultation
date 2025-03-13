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
        public string Nom { get; set; }

        [Required, MaxLength(50)]
        public string Espece { get; set; }

        [MaxLength(50)]
        public string Race { get; set; }

        public int Age { get; set; }

        [Required]
        public string Sexe { get; set; }

        public string Allergies { get; set; }
        public string AnttecedentsMedicaux { get; set; }


        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public List<Vaccination> Vaccinations { get; set; }

        [ForeignKey("AppUser")]
        public Guid OwnerId { get; set; }
        public AppUser Owner { get; set; }

    }

}
