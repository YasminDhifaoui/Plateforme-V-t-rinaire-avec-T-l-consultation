using backend.Data;
using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.AnimalRepo
{
    public class AnimalCRepo : IAnimalCRepo
    {

        private readonly AppDbContext _context;

        public AnimalCRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<AnimalClientDto>> getAnimalsByOwnerId(Guid userId)
        {
            var animals =await _context.Animals
                .Where(animal => animal.OwnerId == userId)
                .Select(Animal => new AnimalClientDto
                {
                    Id = Animal.Id,
                    Name = Animal.Nom,
                    Espece = Animal.Espece,
                    Race = Animal.Race,
                    Age = Animal.Age,
                    Sexe = Animal.Sexe,
                    Allergies = Animal.Allergies,
                    Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                    CreatedAt = Animal.CreatedAt,
                    UpdatedAt = Animal.UpdatedAt,
                }).ToListAsync();
            return animals;
        }
        public async Task<string> AddAnimal(Animal animal)
        {
            if (animal != null)
            {
                await _context.Animals.AddAsync(animal);
                await SaveChanges();
                return "animal added successfully";
            }
            return "failed to add animal";
        }
        public async Task<string> deleteAnimal(Guid id)
        {
            var animal =await _context.Animals.FirstOrDefaultAsync(a => a.Id == id);
            _context.Animals.Remove(animal);
            await SaveChanges();
            return "Animal removed successfully";
        }


        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }



    }
}
