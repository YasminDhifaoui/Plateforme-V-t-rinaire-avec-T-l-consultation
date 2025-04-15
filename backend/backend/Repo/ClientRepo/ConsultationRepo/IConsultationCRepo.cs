using backend.Dtos.ClientDtos.ConsultationDtos;

namespace backend.Repo.ClientRepo.ConsultationRepo
{
    public interface IConsultationCRepo
    {
        public Task<IEnumerable<ConsultationCDto>> GetMyConsultation(Guid id);
    }
}
