using backend.Data;
using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.VaccinationRepo
{
    public class VaccinationVetRepo : IVaccinationVetRepo   
    {
        private readonly AppDbContext _context;

        public VaccinationVetRepo(AppDbContext context)
        {
            _context = context;
        }

        private async Task<bool> HasRendezVous(Guid vetId, Guid animalId)
        {
            return await _context.RendezVous
                .AnyAsync(r => r.VeterinaireId == vetId && r.AnimalId == animalId);
        }

        public async Task<IEnumerable<Vaccination>> GetVeterinaireVaccinations(Guid vetId)
        {
            return await _context.Vaccinations
                .Include(v => v.Animal)
                .Where(v => _context.RendezVous
                    .Any(r => r.VeterinaireId == vetId && r.AnimalId == v.AnimalId))
                .ToListAsync();
        }
        public async Task<IEnumerable<Vaccination>> GetVeterinaireVaccinationsByAnimalId(Guid vetId, Guid animalId)
        {
            var hasAccess = await _context.RendezVous
                .AnyAsync(r => r.VeterinaireId == vetId && r.AnimalId == animalId);

            if (!hasAccess)
                return Enumerable.Empty<Vaccination>();

            return await _context.Vaccinations
                .Where(v => v.AnimalId == animalId)
                .ToListAsync();
        }


        public async Task<string> AddVaccination(Guid vetId, AddVaccinationDto dto)
        {
            if (!await HasRendezVous(vetId, dto.AnimalId))
                return "You do not have a rendezvous with this animal.";

            var vacc = new Vaccination
            {
                Id = Guid.NewGuid(),
                Name = dto.Name,
                Date = dto.Date,
                AnimalId = dto.AnimalId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Vaccinations.Add(vacc);
            await _context.SaveChangesAsync();
            return "Vaccination added successfully.";
        }

        public async Task<string> UpdateVaccination(Guid vetId, Guid vaccId, UpdateVaccinationDto dto)
        {
            var vacc = await _context.Vaccinations.FindAsync(vaccId);
            if (vacc == null)
                return "Vaccination not found.";

            if (!await HasRendezVous(vetId, dto.AnimalId))
                return "You do not have permission to update this vaccination.";

            vacc.Name = dto.Name;
            vacc.Date = dto.Date;
            vacc.AnimalId = dto.AnimalId;
            vacc.UpdatedAt = DateTime.UtcNow;

            _context.Vaccinations.Update(vacc);
            await _context.SaveChangesAsync();
            return "Vaccination updated successfully.";
        }

        public async Task<string> DeleteVaccination(Guid vetId, Guid vaccId)
        {
            var vacc = await _context.Vaccinations
                .Include(v => v.Animal)
                .FirstOrDefaultAsync(v => v.Id == vaccId);

            if (vacc == null)
                return "Vaccination not found.";

            if (!await HasRendezVous(vetId, vacc.AnimalId))
                return "You do not have permission to delete this vaccination.";

            _context.Vaccinations.Remove(vacc);
            await _context.SaveChangesAsync();
            return "Vaccination deleted successfully.";
        }
    }
}
