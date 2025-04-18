using backend.Data;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.RendezVousRepo
{
    public class RendezVousVRepo : IRendezVousVRepo
    {
        private readonly AppDbContext _context;

        public RendezVousVRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<RendezVous>> GetRendezVousByVetId(Guid vetId)
        {
            var rendezVous =await _context.RendezVous
                                     .Where(r => r.VeterinaireId == vetId)
                                     .ToListAsync();

            return rendezVous;
        }

        public async Task<RendezVous> GetRendezVousByAnimalIdAndVetId(Guid animalId, Guid vetId)
        {
            var rendezVous =await _context.RendezVous
                                     .FirstOrDefaultAsync(r => r.AnimalId == animalId && r.VeterinaireId == vetId);

            return rendezVous;
        }

        public async Task<bool> UpdateRendezVousStatus(Guid idVet, Guid rendezVousId, RendezVousStatus newStatus)
        {
            var rendezVous = await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == rendezVousId && r.VeterinaireId == idVet);
            if (rendezVous == null)
                return false;

            rendezVous.Status = newStatus;
            rendezVous.UpdatedAt = DateTime.UtcNow;

            _context.RendezVous.Update(rendezVous);
            await saveChanges();
            return true;
        }


        public async Task saveChanges()
        {
            await _context.SaveChangesAsync();
        }
    }
}
