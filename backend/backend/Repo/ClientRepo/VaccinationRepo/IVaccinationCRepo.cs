using backend.Dtos.ClientDtos.VaccinationDtos;
using backend.Models;

namespace backend.Repo.ClientRepo.VaccinationRepo
{
    public interface IVaccinationCRepo
    {
        Task<IEnumerable<VaccinationCDto>> GetClientVaccinationsAsync(Guid clientId, Guid? animalId = null);

    }
}
