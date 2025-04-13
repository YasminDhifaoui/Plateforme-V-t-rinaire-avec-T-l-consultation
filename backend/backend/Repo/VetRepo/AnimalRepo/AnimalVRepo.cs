using backend.Data;
using backend.Dtos.VetDtos.AnimalDtos;
using backend.Models; 
using System.Linq;

namespace backend.Repo.VetRepo.AnimalRepo
{
    public class AnimalVRepo : IAnimalVRepo
    {
        private readonly AppDbContext _context;

        public AnimalVRepo(AppDbContext context)
        {
            _context = context;
        }

        public IEnumerable<AnimalVetDto> GetAnimalsByVetId(Guid vetId)
        {
            var animalIds = _context.RendezVous
                                    .Where(r => r.VeterinaireId == vetId)
                                    .Select(r => r.AnimalId)
                                    .Distinct()
                                    .ToList();

            var animals = _context.Animals
                                  .Where(a => animalIds.Contains(a.Id))
                                  .ToList();

            var animalDtos = animals.Select(a => new AnimalVetDto
            {
                Id = a.Id,
                Name = a.Nom,
                Espece = a.Espece,
                Race = a.Race,
                Age = a.Age,
                Sexe = a.Sexe,
                Allergies = a.Allergies,
                Anttecedentsmedicaux = a.AnttecedentsMedicaux,
            }).ToList();

            return animalDtos;
        }
    }
}
