using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.ClientRepo.AnimalRepo
{
    public interface IAnimalCRepo
    {
        public IEnumerable<AnimalDto> getAnimalsByOwnerId(Guid userId);
        public string deleteAnimal(Guid id);
        public string AddAnimal(Animal animal);
        void SaveChanges();

    }
}
