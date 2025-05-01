using backend.Dtos.ClientDtos.RendezVousDtos;
using backend.Models;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public interface IRendezVousCRepo
    {
        public Task<IEnumerable<RendezVousCDto>> getRendezVousByClientId(Guid clientId);
        public Task<string> AddRendezVous(RendezVous rendezVous);
        public Task<string> DeleteRendezVous(Guid id);
        public Task SaveChanges();
    }
}
