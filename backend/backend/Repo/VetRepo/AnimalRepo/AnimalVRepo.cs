using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Dtos.VetDtos.AnimalDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
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

        public async  Task<IEnumerable<AnimalVetDto>> GetAnimalsByVetId(Guid vetId)
        {

            var animalIds = await _context.RendezVous
                                    .Where(r => r.VeterinaireId == vetId)
                                    .Select(r => r.AnimalId)
                                    .Distinct()
                                    .ToListAsync();


            var animalDtos = await _context.Animals
              .Where(a => animalIds.Contains(a.Id))
              .Select(a => new AnimalVetDto
              {
                  Id = a.Id,
                  Name = a.Nom,
                  Espece = a.Espece,
                  Race = a.Race,
                  Age = a.Age,
                  Sexe = a.Sexe,
                  Allergies = a.Allergies,
                  Anttecedentsmedicaux = a.AnttecedentsMedicaux,
              }).ToListAsync();


            return animalDtos;
        }

       

        public async Task<string> UpdateAnimalAsync(Guid vetId, Guid animalId, UpdateAnimalVetDto updatedAnimal)
        {
            var vet = await _context.veterinaires.FirstOrDefaultAsync(u => u.AppUserId == vetId);
            if (vet == null)
                return "Vet Id not found.";

            var animalToUpdate = await _context.Animals.FirstOrDefaultAsync(a => a.Id == animalId);
            if (animalToUpdate == null)
                return "Animal not found.";


            animalToUpdate.Age = updatedAnimal.Age;
            animalToUpdate.Allergies = updatedAnimal.Allergies ;
            animalToUpdate.AnttecedentsMedicaux = updatedAnimal.AntecedentsMedicaux ;
            animalToUpdate.UpdatedAt = DateTime.UtcNow;


            _context.Animals.Update(animalToUpdate);
            await SaveChanges();
            return "Animal updated successfully";
        }
        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }

        public async Task<List<AnimalVetDto>> GetAnimalsByClientIdAndVetIdAsync(Guid vetId, Guid clientId)
        {
            var animalIdsWithVet = await _context.RendezVous
                .Where(r => r.VeterinaireId == vetId && r.Animal.OwnerId == clientId)
                .Select(r => r.AnimalId)
                .Distinct()
                .ToListAsync();

            var animals = await _context.Animals
                .Where(a => animalIdsWithVet.Contains(a.Id))
                .Select(a => new AnimalVetDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    OwnerId = a.OwnerId
                })
                .ToListAsync();

            return animals;
        }


    }
}
