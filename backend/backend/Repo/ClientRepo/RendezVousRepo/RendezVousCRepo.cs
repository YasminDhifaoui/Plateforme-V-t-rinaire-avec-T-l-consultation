using backend.Data;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public class RendezVousCRepo : IRendezVousCRepo
    {
        public AppDbContext _context;
        public RendezVousCRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<RendezVous>> getRendezVousByClientId(Guid clientId)
        {
            var Rvous =await _context.RendezVous
                            .Where(r => r.ClientId == clientId)
                            .Select(r => new RendezVous
                            {
                                Id = r.Id,
                                Date = r.Date,
                                Veterinaire = r.Veterinaire,
                                Client = r.Client,
                                Animal = r.Animal,
                                Status = r.Status,
                                CreatedAt = r.CreatedAt,
                                UpdatedAt = r.UpdatedAt,
                            }).ToListAsync();
            return Rvous;
        }
        public async Task<string> AddRendezVous(RendezVous rendezVous)
        {
            if (rendezVous != null)
            {
                await _context.RendezVous.AddAsync(rendezVous);
                await SaveChanges();
                return "Rendez-vous added successfully";
            }
            return "failed to add rendez-vous";
        }
        public async Task<string> DeleteRendezVous(Guid id)
        {
            var Rvous =await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == id);
            _context.RendezVous.Remove(Rvous);
            await SaveChanges();
            return ("Rendez-vous removed successfully");
        }

        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }

    }
}
