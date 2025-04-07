using backend.Dtos.RendezVousDtos;
using backend.Models;

namespace backend.Repo.Rendez_vousRepo
{
    public interface IRendezVousRepo
    {
        public IEnumerable<RendezVous> getAllRendezVous();
        public IEnumerable<RendezVous> getRendezVousById();
        public IEnumerable<RendezVous> getRendezVousByVetId();
        public IEnumerable<RendezVous> getRendezVousByClientId();
        public IEnumerable<RendezVous> getRendezVousByAnimalId();
        public IEnumerable<RendezVous> getRendezVousByDate();
        public IEnumerable<RendezVous> getRendezVousByStatus();

        public string AddRendezVous(RendezVous rendezVous);
        public string UpdateRendezVous(Guid id,UpdateRendezVousDto updatedRendezVous);
        public string DeleteRendezVous(Guid id);
        public void SaveChanges();

    }
}
