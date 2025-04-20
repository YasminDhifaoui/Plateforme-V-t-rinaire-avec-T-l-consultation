using backend.Data;
using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo.VaccinationRepo
{
    public class VaccinationRepo : IVaccinationRepo
    {
        private readonly AppDbContext _context;

        public VaccinationRepo(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Vaccination>> GetAllVaccinations()
        {
            return await _context.Vaccinations.ToListAsync();
        }

        public async Task<Vaccination> GetVaccinationById(Guid id)
        {
            return await _context.Vaccinations.FirstOrDefaultAsync(v => v.Id == id);
        }

        public async Task<IEnumerable<Vaccination>> GetVaccinationByName(string name)
        {
            return await _context.Vaccinations
                                     .Where(v => v.Name == name)
                                     .ToListAsync();
        }

        public async Task<string> AddVaccination(AddVaccinationDto dto)
        {
            var animal = await _context.Animals.FindAsync(dto.AnimalId);
            if (animal == null)
                return "No animal with this ID";

            var vacc = new Vaccination
            {
                Id = Guid.NewGuid(),
                Name = dto.Name,
                Date = dto.Date,
                AnimalId = dto.AnimalId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
            };

            _context.Vaccinations.Add(vacc);
            await SaveChanges();

            return "Vaccination added successfully";
        }

        public async Task<string> UpdateVaccination(Guid id, UpdateVaccinationDto dto)
        {
            var vacc = await _context.Vaccinations.FindAsync(id);
            if (vacc == null)
                return "No vaccination with this ID";

            var animal = await _context.Animals.FindAsync(dto.AnimalId);
            if (animal == null)
                return "No animal with this ID";

            vacc.Name = dto.Name;
            vacc.Date = dto.Date;
            vacc.AnimalId = dto.AnimalId;
            vacc.UpdatedAt = DateTime.UtcNow;

            _context.Vaccinations.Update(vacc);
            await SaveChanges();

            return "Vaccination updated successfully";
        }

        public async Task<string> DeleteVaccination(Guid id)
        {
            var vacc = await _context.Vaccinations.FindAsync(id);
            if (vacc == null)
                return "No vaccination with this ID";

            _context.Vaccinations.Remove(vacc);
            await SaveChanges();

            return "Vaccination deleted successfully";
        }
        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }

     
    }
}
