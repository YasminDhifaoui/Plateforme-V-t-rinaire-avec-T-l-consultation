using backend.Data;
using backend.Dtos.ClientDtos.RendezVousDtos;
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
        public async Task<IEnumerable<RendezVousCDto>> getRendezVousByClientId(Guid clientId)
        {
            var Rvous = await _context.RendezVous
                .Where(r => r.ClientId == clientId)
                .Include(r => r.Veterinaire)
                .Include(r => r.Animal)
                .Select(r => new RendezVousCDto
                {
                    Id = r.Id,
                    Date = r.Date,
                    VetName = r.Veterinaire.FirstName + " " + r.Veterinaire.LastName,
                    AnimalName = r.Animal.Nom,
                    Status = r.Status 
                })
                .ToListAsync();

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
