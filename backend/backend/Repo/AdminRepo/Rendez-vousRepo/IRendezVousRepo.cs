using backend.Dtos.AdminDtos.RendezVousDtos;
using backend.Models;

namespace backend.Repo.Rendez_vousRepo
{
    public interface IRendezVousRepo
    {
        public IEnumerable<RendezVous> getAllRendezVous();
        public IEnumerable<RendezVous> getRendezVousById(Guid id);
        public IEnumerable<RendezVous> getRendezVousByVetId(Guid vetId);
        public IEnumerable<RendezVous> getRendezVousByClientId(Guid clientId);
        public IEnumerable<RendezVous> getRendezVousByAnimalId(Guid animalId);
        public IEnumerable<RendezVous> getRendezVousByStatus(RendezVousStatus status);

        public string AddRendezVous(RendezVous rendezVous);
        public string UpdateRendezVous(Guid id,UpdateRendezVousAdminDto updatedRendezVous);
        public string DeleteRendezVous(Guid id);
        public void SaveChanges();

    }
}
