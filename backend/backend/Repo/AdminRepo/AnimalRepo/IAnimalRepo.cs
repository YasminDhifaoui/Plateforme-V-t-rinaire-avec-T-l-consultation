using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.AnimalRepo
{
    public interface IAnimalRepo
    {
        public IEnumerable<AnimalDto> getAllAnimals();
        public AnimalDto getAnimalById(Guid id);

        public IEnumerable<AnimalDto> getAnimalsByOwnerId(Guid userId);
        public IEnumerable<AnimalDto> getAnimalsByName(string name);
        public IEnumerable<AnimalDto> getAnimalsByEspece(string espece);
        public IEnumerable<AnimalDto> getAnimalsByRace(string race);

        public string UpdateAnimal(Guid animalId, UpdateAnimalDto updatedAnimal);

        public string deleteAnimal(Guid id);
        public string AddAnimal(Animal animal);
        void SaveChanges();


    }
}
