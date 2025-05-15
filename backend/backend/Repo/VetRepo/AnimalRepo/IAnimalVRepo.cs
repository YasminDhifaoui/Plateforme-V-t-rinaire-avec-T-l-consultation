using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Dtos.VetDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.VetRepo.AnimalRepo
{
    public interface IAnimalVRepo
    {
        Task<IEnumerable<AnimalVetDto>> GetAnimalsByVetId(Guid vetId);
        Task<List<AnimalVetDto>> GetAnimalsByClientIdAndVetIdAsync(Guid vetId, Guid clientId);

        Task<string> UpdateAnimalAsync(Guid vetId, Guid animalId, UpdateAnimalVetDto updatedAnimal);
        Task SaveChanges();


    }
}
