using backend.Models;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.ClientDtos.VaccinationDtos
{
    public class VaccinationCDto
    {

        public string Name { get; set; }

        public DateTime Date { get; set; }

        public string AnimalName { get; set; }
    }
}
