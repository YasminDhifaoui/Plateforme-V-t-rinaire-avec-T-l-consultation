using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Models;

namespace backend.Repo.VetRepo.VaccinationRepo
{
    public interface IVaccinationVetRepo
    {
        Task<IEnumerable<Vaccination>> GetVeterinaireVaccinations(Guid vetId);
        Task<IEnumerable<Vaccination>> GetVeterinaireVaccinationsByAnimalId(Guid vetId, Guid animalId);
        Task<string> AddVaccination(Guid vetId, AddVaccinationDto dto);
        Task<string> UpdateVaccination(Guid vetId, Guid vaccId, UpdateVaccinationDto dto);
        Task<string> DeleteVaccination(Guid vetId, Guid vaccId);
    }
}
