using backend.Models;
using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.ClientDtos.RendezVousDtos
{
    public class AddRendezVous
    {
        public Guid VetId { get; set; }
        public Guid AnimalId { get; set; }
        public DateTime Date { get; set; }

    }
}
