using backend.Data;
using backend.Dtos.AdminDtos.RendezVousDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.Rendez_vousRepo
{
    public class RendezVousRepo : IRendezVousRepo
    {
        public AppDbContext _context;
        public RendezVousRepo(AppDbContext context) { 
            _context = context;
        }
        public async Task<IEnumerable<RendezVous>> getAllRendezVous()
        {
            var Rvous = await _context.RendezVous.Select(r => new RendezVous
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
        public async Task<RendezVous> getRendezVousById(Guid id)
        {
            var Rvous = await _context.RendezVous
                .Where(r => r.Id == id)
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
            }).FirstOrDefaultAsync();
            return Rvous;
        }
        public async Task<IEnumerable<RendezVous>> getRendezVousByVetId(Guid vetId)
        {
            var Rvous = await _context.RendezVous
                .Where(r => r.VeterinaireId == vetId)
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
        public async Task<IEnumerable<RendezVous>> getRendezVousByClientId(Guid clientId)
        {
            var Rvous = await _context.RendezVous
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
        public async Task<IEnumerable<RendezVous>> getRendezVousByAnimalId(Guid animalId)
        {
            var Rvous = await _context.RendezVous
                            .Where(r => r.AnimalId == animalId)
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


        public async Task<IEnumerable<RendezVous>> getRendezVousByStatus(RendezVousStatus status)
        {
            var Rvous = await _context.RendezVous
                            .Where(r => r.Status == status)
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

        public async Task<string> UpdateRendezVous(Guid id, UpdateRendezVousAdminDto updatedRendezVous)
        {
            var vet = await _context.veterinaires.FirstOrDefaultAsync(u => u.AppUserId == updatedRendezVous.VetId);
            if (vet == null)
                return ("Veterinaire not found." );

            var client = await _context.clients.FirstOrDefaultAsync(u => u.AppUserId == updatedRendezVous.ClientId);
            if (client == null)
                return ("Client not found.");

            var animal = await _context.Animals.FirstOrDefaultAsync(u => u.Id == updatedRendezVous.AnimalId);
            if (animal == null)
                return ("Animal not found.");


            var RvousToUpdate = await _context.RendezVous.FindAsync(id);

            if (RvousToUpdate == null)
                return "Rendez-vous not found !";

            RvousToUpdate.Date = updatedRendezVous.Date.ToUniversalTime();
            RvousToUpdate.Status = updatedRendezVous.Status;
            RvousToUpdate.VeterinaireId = updatedRendezVous.VetId;
            RvousToUpdate.ClientId = updatedRendezVous.ClientId;
            RvousToUpdate.AnimalId = updatedRendezVous.AnimalId;

            RvousToUpdate.UpdatedAt = DateTime.UtcNow.ToUniversalTime();

            _context.RendezVous.Update(RvousToUpdate);
            await SaveChanges();
            return "Rendez-vous updated successfully";
        }
        public async Task<string> DeleteRendezVous(Guid id)
        {
            var Rvous = await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == id);
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
