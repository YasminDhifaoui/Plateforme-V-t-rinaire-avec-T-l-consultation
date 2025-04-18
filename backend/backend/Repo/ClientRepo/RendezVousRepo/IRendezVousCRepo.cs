using backend.Models;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public interface IRendezVousCRepo
    {
        public Task<IEnumerable<RendezVous>> getRendezVousByClientId(Guid clientId);
        public Task<string> AddRendezVous(RendezVous rendezVous);
        public Task<string> DeleteRendezVous(Guid id);
        public Task SaveChanges();
    }
}
