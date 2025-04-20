using backend.Models;

namespace backend.Dtos.AdminDtos.VaccinationDtos
{
    public class AddVaccinationDto
    {
        public string Name { get; set; }
        public DateTime Date { get; set; }
        public Guid AnimalId { get; set; }
    }
}
