using backend.Data;
using backend.Models;

namespace backend.Repo.VetRepo.RendezVousRepo
{
    public class RendezVousVRepo : IRendezVousVRepo
    {
        private readonly AppDbContext _context;

        public RendezVousVRepo(AppDbContext context)
        {
            _context = context;
        }
        public IEnumerable<RendezVous> GetRendezVousByVetId(Guid vetId)
        {
            var rendezVous = _context.RendezVous
                                     .Where(r => r.VeterinaireId == vetId)
                                     .ToList();

            return rendezVous;
        }

        public RendezVous GetRendezVousByAnimalIdAndVetId(Guid animalId, Guid vetId)
        {
            var rendezVous = _context.RendezVous
                                     .FirstOrDefault(r => r.AnimalId == animalId && r.VeterinaireId == vetId);

            return rendezVous;
        }

    }
}
