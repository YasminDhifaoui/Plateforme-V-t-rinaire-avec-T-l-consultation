
using backend.Data;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Dtos.ClientDtos.ConsultationDtos;

namespace backend.Repo.ClientRepo.ConsultationRepo
{
    public class ConsultationCRepo : IConsultationCRepo
    {
        public readonly AppDbContext _context;
        public ConsultationCRepo (AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ConsultationCDto>> GetMyConsultation(Guid id)
        {
            var consultations = await _context.Consultations
                           .Include(c => c.RendezVous)
                            .ThenInclude(r => r.Animal)
                            .Include(c => c.Veterinaire)
                           .Where(c => c.RendezVous.ClientId == id)
                           .Select(c => new ConsultationCDto
                           {
                               Id = c.Id,
                               Date = c.Date,
                               Diagnostic = c.Diagnostic,
                               Treatment = c.Treatment,
                               Prescription = c.Prescriptions,
                               Notes = c.Notes,
                               DocumentPath = c.DocumentPath,
                               CreatedAt = c.CreatedAt,
                               UpdatedAt = c.UpdatedAt,
                               VeterinaireName = c.Veterinaire.UserName!,
                               AnimalName = c.RendezVous.Animal.Nom
                           })
                           .ToListAsync();

            return consultations;
        }
    }
}
