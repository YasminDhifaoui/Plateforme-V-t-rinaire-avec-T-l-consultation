using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Dtos.AdminDtos.VetDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.VaccinationRepo
{
    public interface IVaccinationRepo
    {
        Task<IEnumerable<Vaccination>> GetAllVaccinations();
        Task<Vaccination> GetVaccinationById(Guid id);
        Task<IEnumerable<Vaccination>> GetVaccinationByName(string name);

        Task<string> UpdateVaccination(Guid VaccId, UpdateVaccinationDto updatedVacc);
        Task<string> DeleteVaccination(Guid VaccId);
        Task<string> AddVaccination(AddVaccinationDto vaccination);

        Task SaveChanges();
    }
}
