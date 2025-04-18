using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

namespace backend.Repo.AdminRepo.AnimalRepo
{
    public class AnimalRepo : IAnimalRepo
    {

        private readonly AppDbContext _context;

        public AnimalRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<AnimalAdminDto>> GetAllAnimalsAsync()
        {
            var animals = await _context.Animals
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).ToListAsync();

            return animals;
        }

        public async Task<AnimalAdminDto> GetAnimalByIdAsync(Guid id)
        {
            return await _context.Animals
                .Where(a => a.Id == id)
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).FirstOrDefaultAsync();


        }

        public async Task<IEnumerable<AnimalAdminDto>> GetAnimalsByOwnerIdAsync(Guid userId)
        {
            return await _context.Animals
                .Where(a => a.OwnerId == userId)
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).ToListAsync();
        }

        public async Task<IEnumerable<AnimalAdminDto>> GetAnimalsByNameAsync(string name)
        {
            return await _context.Animals
                .Where(a => a.Nom == name)
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).ToListAsync();
        }

        public async Task<IEnumerable<AnimalAdminDto>> GetAnimalsByEspeceAsync(string espece)
        {
            return await _context.Animals
                .Where(a => a.Espece == espece)
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).ToListAsync();
        }

        public async Task<IEnumerable<AnimalAdminDto>> GetAnimalsByRaceAsync(string race)
        {
            return await _context.Animals
                .Where(a => a.Race == race)
                .Select(a => new AnimalAdminDto
                {
                    Id = a.Id,
                    Name = a.Nom,
                    Espece = a.Espece,
                    Race = a.Race,
                    Age = a.Age,
                    Sexe = a.Sexe,
                    Allergies = a.Allergies,
                    Anttecedentsmedicaux = a.AnttecedentsMedicaux,
                    OwnerId = a.OwnerId,
                    CreatedAt = a.CreatedAt,
                    UpdatedAt = a.UpdatedAt,
                }).ToListAsync();
        }

        public async Task<string> AddAnimalAsync(Animal animal)
        {
            if (animal != null)
            {
                await _context.Animals.AddAsync(animal);
                await SaveChangesAsync();
                return "Animal added successfully";
            }
            return "Failed to add animal";
        }

        public async Task<string> UpdateAnimalAsync(Guid animalId, UpdateAnimalAdminDto updatedAnimal)
        {
            var owner = await _context.Users.FirstOrDefaultAsync(u => u.Id == updatedAnimal.OwnerId);
            if (owner == null)
                return "Owner with this Id not found.";

            var animalToUpdate = await _context.Animals.FindAsync(animalId);
            if (animalToUpdate == null)
                return "Animal not found!";

            animalToUpdate.Nom = updatedAnimal.Name;
            animalToUpdate.Espece = updatedAnimal.Espece;
            animalToUpdate.Race = updatedAnimal.Race;
            animalToUpdate.Age = updatedAnimal.Age;
            animalToUpdate.Sexe = updatedAnimal.Sexe;
            animalToUpdate.OwnerId = updatedAnimal.OwnerId;
            animalToUpdate.UpdatedAt = DateTime.UtcNow;
            animalToUpdate.Allergies = updatedAnimal.Allergies;
            animalToUpdate.AnttecedentsMedicaux = updatedAnimal.AntecedentsMedicaux;

            _context.Animals.Update(animalToUpdate);
            await SaveChangesAsync();
            return "Animal updated successfully";
        }

        public async Task<string> DeleteAnimalAsync(Guid id)
        {
            var animal = await _context.Animals.FirstOrDefaultAsync(a => a.Id == id);
           
            _context.Animals.Remove(animal);
            await SaveChangesAsync();
            return "Animal removed successfully";
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }

    }

}
