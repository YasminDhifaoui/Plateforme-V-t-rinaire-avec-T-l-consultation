using backend.Data;
using backend.Dtos.ClientDtos.VaccinationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.VaccinationRepo
{
    public class VaccinationCRepo : IVaccinationCRepo
    {
        private readonly AppDbContext _context;

        public VaccinationCRepo(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<VaccinationCDto>> GetClientVaccinationsAsync(Guid clientId, Guid? animalId = null)
        {
            var query = _context.Vaccinations
                .Include(v => v.Animal)
                .Where(v => v.Animal.OwnerId == clientId);

            if (animalId.HasValue)
                query = query.Where(v => v.AnimalId == animalId.Value);

            return await query
                .Select(v => new VaccinationCDto
                {
                    Name = v.Name,
                    Date = v.Date,
                    AnimalName = v.Animal.Nom,
                })
                .ToListAsync();
        }
    }
}
