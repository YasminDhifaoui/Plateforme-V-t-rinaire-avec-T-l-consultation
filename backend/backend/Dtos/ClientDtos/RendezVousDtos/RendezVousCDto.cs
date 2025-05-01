using backend.Models;

namespace backend.Dtos.ClientDtos.RendezVousDtos
{
    public class RendezVousCDto
    {
        public Guid Id { get; set; }
        public DateTime Date { get; set; }
        public string VetName { get; set; }
        public string AnimalName { get; set; }
        public RendezVousStatus Status { get; set; }
    }
}
