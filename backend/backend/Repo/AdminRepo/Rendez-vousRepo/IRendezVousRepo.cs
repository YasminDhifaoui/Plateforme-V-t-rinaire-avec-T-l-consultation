using backend.Dtos.AdminDtos.RendezVousDtos;
using backend.Models;

namespace backend.Repo.Rendez_vousRepo
{
    public interface IRendezVousRepo
    {
        public Task<IEnumerable<RendezVous>> getAllRendezVous();
        public Task<RendezVous> getRendezVousById(Guid id);
        public Task<IEnumerable<RendezVous>> getRendezVousByVetId(Guid vetId);
        public Task<IEnumerable<RendezVous>> getRendezVousByClientId(Guid clientId);
        public Task<IEnumerable<RendezVous>> getRendezVousByAnimalId(Guid animalId);
        public Task<IEnumerable<RendezVous>> getRendezVousByStatus(RendezVousStatus status);

        public Task<string> AddRendezVous(RendezVous rendezVous);
        public Task<string> UpdateRendezVous(Guid id,UpdateRendezVousAdminDto updatedRendezVous);
        public Task<string> DeleteRendezVous(Guid id);
        public Task SaveChanges();

    }
}
