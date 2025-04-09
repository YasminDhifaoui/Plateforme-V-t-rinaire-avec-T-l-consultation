using backend.Models;
using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.RendezVousDtos
{
    public class AddRendezVousDto
    {
        public Guid VetId { get; set; }
        public Guid ClientId { get; set; }
        public Guid AnimalId { get; set; }
        public DateTime Date { get; set; }

        [EnumDataType(typeof(RendezVousStatus))]
        public RendezVousStatus Status { get; set; }
    }

}
