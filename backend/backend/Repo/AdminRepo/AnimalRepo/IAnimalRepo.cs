using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.AnimalRepo
{
    public interface IAnimalRepo
    {
        public IEnumerable<AnimalAdminDto> getAllAnimals();
        public AnimalAdminDto getAnimalById(Guid id);

        public IEnumerable<AnimalAdminDto> getAnimalsByOwnerId(Guid userId);
        public IEnumerable<AnimalAdminDto> getAnimalsByName(string name);
        public IEnumerable<AnimalAdminDto> getAnimalsByEspece(string espece);
        public IEnumerable<AnimalAdminDto> getAnimalsByRace(string race);

        public string UpdateAnimal(Guid animalId, UpdateAnimalAdminDto updatedAnimal);

        public string deleteAnimal(Guid id);
        public string AddAnimal(Animal animal);
        void SaveChanges();


    }
}
