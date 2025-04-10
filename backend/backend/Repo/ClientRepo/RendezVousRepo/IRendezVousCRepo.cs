using backend.Models;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public interface IRendezVousCRepo
    {
        public IEnumerable<RendezVous> getRendezVousByClientId(Guid clientId);
        public string AddRendezVous(RendezVous rendezVous);
        public string DeleteRendezVous(Guid id);
        public void SaveChanges();
    }
}
