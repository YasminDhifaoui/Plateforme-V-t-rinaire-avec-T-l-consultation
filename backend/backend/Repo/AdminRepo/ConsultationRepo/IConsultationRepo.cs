using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.ConsultationRepo
{
    public interface IConsultationRepo
    {
        public Task<IEnumerable<Consultation>> GetAllConsultations();
        public Task<Consultation> GetConsultationById(Guid id);
        public Task<Consultation> AddConsultation(AddConsultationDto consultation);
        public string UpdateAsync(Guid id, UpdateConsultationDto updatedConsultation);
        public string DeleteAsync(Guid id);
        public void saveChanges();
    }
    
}
