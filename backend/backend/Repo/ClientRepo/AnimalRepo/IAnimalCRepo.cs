using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.ClientRepo.AnimalRepo
{
    public interface IAnimalCRepo
    {
        public Task<IEnumerable<AnimalClientDto>> getAnimalsByOwnerId(Guid userId);
        public Task<string> deleteAnimal(Guid id);
        public Task<string> AddAnimal(Animal animal);
        public Task SaveChanges();
         
    }
}
