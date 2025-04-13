using backend.Data;
using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.ClientRepo.AnimalRepo
{
    public class AnimalCRepo : IAnimalCRepo
    {

        private readonly AppDbContext _context;

        public AnimalCRepo(AppDbContext context)
        {
            _context = context;
        }
        public IEnumerable<AnimalClientDto> getAnimalsByOwnerId(Guid userId)
        {
            var animals = _context.Animals
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
                }).ToList();
            return animals;
        }
        public string AddAnimal(Animal animal)
        {
            if (animal != null)
            {
                _context.Animals.Add(animal);
                SaveChanges();
                return "animal added successfully";
            }
            return "failed to add animal";
        }
        public string deleteAnimal(Guid id)
        {
            var animal = _context.Animals.FirstOrDefault(a => a.Id == id);
            _context.Animals.Remove(animal);
            SaveChanges();
            return "Animal removed successfully";
        }


        public void SaveChanges()
        {
            _context.SaveChanges();
        }



    }
}
