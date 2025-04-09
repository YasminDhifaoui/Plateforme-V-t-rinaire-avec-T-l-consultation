using backend.Data;
using backend.Dtos.AdminDtos;
using backend.Dtos.AnimalDtos;
using backend.Models;
using Microsoft.AspNetCore.Http.HttpResults;

namespace backend.Repo.AnimalRepo
{
    public class AnimalRepo : IAnimalRepo
    {

        private readonly AppDbContext _context;

        public AnimalRepo(AppDbContext context)
        {
            _context = context;
        }
        public IEnumerable<AnimalDto> getAllAnimals()
        {
            var animals = _context.Animals.Select(Animal => new AnimalDto
            {
                Id = Animal.Id,
                Name = Animal.Nom,
                Espece = Animal.Espece,
                Race = Animal.Race,
                Age = Animal.Age,
                Sexe = Animal.Sexe,
                Allergies = Animal.Allergies,
                Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                OwnerId = Animal.OwnerId,
                CreatedAt = Animal.CreatedAt,
                UpdatedAt = Animal.UpdatedAt,
            }).ToList();
            return animals;
        }
        public AnimalDto getAnimalById(Guid id)
        {
            var animals = _context.Animals
                .Where(animal => animal.Id == id)
                .Select(Animal => new AnimalDto
                {
                    Id = Animal.Id,
                    Name = Animal.Nom,
                    Espece = Animal.Espece,
                    Race = Animal.Race,
                    Age = Animal.Age,
                    Sexe = Animal.Sexe,
                    Allergies = Animal.Allergies,
                    Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                    OwnerId = Animal.OwnerId,
                    CreatedAt = Animal.CreatedAt,
                    UpdatedAt = Animal.UpdatedAt,
                }).FirstOrDefault();
            return animals;
        }
        public IEnumerable<AnimalDto> getAnimalsByOwnerId(Guid userId)
        {
            var animals = _context.Animals
                .Where(animal => animal.OwnerId == userId)
                .Select(Animal => new AnimalDto
                {
                    Id = Animal.Id,
                    Name = Animal.Nom,
                    Espece = Animal.Espece,
                    Race = Animal.Race,
                    Age = Animal.Age,
                    Sexe = Animal.Sexe,
                    Allergies = Animal.Allergies,
                    Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                    OwnerId = Animal.OwnerId,
                    CreatedAt = Animal.CreatedAt,
                    UpdatedAt = Animal.UpdatedAt,
                }).ToList();
            return animals;
        }


        public IEnumerable<AnimalDto> getAnimalsByName(string name)
        {

            var animals = _context.Animals
                .Where(animal => animal.Nom == name)
                .Select(Animal => new AnimalDto
                {
                    Id = Animal.Id,
                    Name = Animal.Nom,
                    Espece = Animal.Espece,
                    Race = Animal.Race,
                    Age = Animal.Age,
                    Sexe = Animal.Sexe,
                    Allergies = Animal.Allergies,
                    Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                    OwnerId = Animal.OwnerId,
                    CreatedAt = Animal.CreatedAt,
                    UpdatedAt = Animal.UpdatedAt,
                }).ToList();
            return animals;
        }

        public IEnumerable<AnimalDto> getAnimalsByEspece(string espece)
        {
            var animals = _context.Animals
                .Where(animal => animal.Espece == espece)
                .Select(Animal => new AnimalDto
            {
                Id = Animal.Id,
                Name = Animal.Nom,
                Espece = Animal.Espece,
                Race = Animal.Race,
                Age = Animal.Age,
                Sexe = Animal.Sexe,
                Allergies = Animal.Allergies,
                Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                OwnerId = Animal.OwnerId,
                CreatedAt = Animal.CreatedAt,
                UpdatedAt = Animal.UpdatedAt,
            }).ToList();
            return animals;
        }

        public IEnumerable<AnimalDto> getAnimalsByRace(string race)
        {

            var animals = _context.Animals
                .Where(animal => animal.Race == race)
                .Select(Animal => new AnimalDto
                {
                    Id = Animal.Id,
                    Name = Animal.Nom,
                    Espece = Animal.Espece,
                    Race = Animal.Race,
                    Age = Animal.Age,
                    Sexe = Animal.Sexe,
                    Allergies = Animal.Allergies,
                    Anttecedentsmedicaux = Animal.AnttecedentsMedicaux,
                    OwnerId = Animal.OwnerId,
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
                this.SaveChanges();
                return "animal added successfully";
            }
            return "failed to add animal";
        }

        public string UpdateAnimal(Guid animalId, UpdateAnimalDto updatedAnimal)
        {

            var owner = _context.Users.FirstOrDefault(u => u.Id == updatedAnimal.OwnerId);
            if (owner == null)
                return "Owner with this Id not found.";

            var animalToUpdate = _context.Animals.Find(animalId);

            if (animalToUpdate == null)
                return "Animal not found !";

            animalToUpdate.Nom = updatedAnimal.Name;
            animalToUpdate.Espece = updatedAnimal.Espece;
            animalToUpdate.Race = updatedAnimal.Race;
            animalToUpdate.Age = updatedAnimal.Age;
            animalToUpdate.Sexe = updatedAnimal.Sexe;
            animalToUpdate.OwnerId = updatedAnimal.OwnerId;
            animalToUpdate.UpdatedAt = DateTime.Now;
            animalToUpdate.Allergies = updatedAnimal.Allergies;
            animalToUpdate.AnttecedentsMedicaux =animalToUpdate.AnttecedentsMedicaux;

            _context.Animals.Update(animalToUpdate);
            this.SaveChanges();
            return "Animal updated successfully";
        }

        public string deleteAnimal(Guid id)
        {
            var animal = _context.Animals.FirstOrDefault(a => a.Id == id);
            _context.Animals.Remove(animal);
            this.SaveChanges();
            return ("Animal removed successfully");
        }


        public void SaveChanges()
        {
            _context.SaveChanges();
        }

    }

}
