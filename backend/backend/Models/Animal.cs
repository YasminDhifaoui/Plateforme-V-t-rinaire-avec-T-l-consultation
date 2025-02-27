using backend.Data;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Animal
    {     
            [Key]
            public int Id { get; set; }

            [Required, MaxLength(100)]
            public string Name { get; set; }

            [Required, MaxLength(50)]
            public string Species { get; set; }

            [MaxLength(50)]
            public string Breed { get; set; }

            public int Age { get; set; }

            [Required]
            public string Sex { get; set; } 

            public string Allergies { get; set; }
            public string MedicalHistory { get; set; }

    
            /*[ForeignKey("User")]
            public int OwnerId { get; set; }
            public User Owner { get; set; }

       
            public List<Vaccination> Vaccinations { get; set; }*/

            public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
            public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        }
    
}
