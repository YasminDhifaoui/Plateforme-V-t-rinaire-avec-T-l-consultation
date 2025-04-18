using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.ConsultationRepo
{
    public interface IConsultationRepo
    {
        public Task<IEnumerable<Consultation>> GetAllConsultations();
        public Task<Consultation> GetConsultationById(Guid id);
        public Task<Consultation> AddConsultation(AddConsultationDto consultation);
        public Task<string> UpdateAsync(Guid id, UpdateConsultationDto updatedConsultation);
        public Task<string> DeleteAsync(Guid id);
        public Task saveChanges();
    }
    
}
