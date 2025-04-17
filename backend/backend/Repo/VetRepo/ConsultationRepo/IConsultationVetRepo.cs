using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Dtos.VetDtos.ConsultationDtos;
using backend.Models;

namespace backend.Repo.VetRepo.ConsultationRepo
{
    public interface IConsultationVetRepo
    {
        Task<IEnumerable<ConsultationVetDto>> GetConsultations(Guid clientId);
        Task<ConsultationVetDto> AddConsultation(AddConsultationVetDto dto, Guid vetId);
         Task<bool> UpdateConsultation(Guid consultationId, UpdateConsultationVetDto dto, Guid vetId);
        Task<bool> DeleteConsultation(Guid consultationId, Guid vetId);

        void saveChanges();

    }
}
