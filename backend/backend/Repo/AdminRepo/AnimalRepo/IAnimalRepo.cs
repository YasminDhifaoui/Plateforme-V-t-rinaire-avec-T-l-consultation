using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

namespace backend.Repo.AdminRepo.AnimalRepo
{
    public interface IAnimalRepo
    {
        Task<IEnumerable<AnimalAdminDto>> GetAllAnimalsAsync();
        Task<AnimalAdminDto> GetAnimalByIdAsync(Guid id);
        Task<IEnumerable<AnimalAdminDto>> GetAnimalsByOwnerIdAsync(Guid userId);
        Task<IEnumerable<AnimalAdminDto>> GetAnimalsByNameAsync(string name);
        Task<IEnumerable<AnimalAdminDto>> GetAnimalsByEspeceAsync(string espece);
        Task<IEnumerable<AnimalAdminDto>> GetAnimalsByRaceAsync(string race);

        Task<string> UpdateAnimalAsync(Guid animalId, UpdateAnimalAdminDto updatedAnimal);
        Task<string> DeleteAnimalAsync(Guid id);
        Task<string> AddAnimalAsync(Animal animal);

        Task SaveChangesAsync();


    }
}
