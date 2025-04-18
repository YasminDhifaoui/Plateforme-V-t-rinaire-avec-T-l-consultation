using backend.Dtos.AdminDtos;
using backend.Dtos.AdminDtos.VetDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.VetRepo
{
    public interface IVetRepo
    {
        Task<IEnumerable<VetDto>> GetVeterinaires();
        Task<VetDto> GetVeterinaireById(Guid id);
        Task<VetDto> GetVeterinaireByUsername(string username);

        Task<string> UpdateVeterinaire(Guid UserId, UpdateVetDto updatedVet);
        Task<string> DeleteVeterinaire(Guid id);
        Task<string> AddVeterinaire(Veterinaire veterinaire);

        Task SaveChanges();
    }
}
