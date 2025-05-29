
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
                            .Include(r => r.Client).ThenInclude(cl => cl.AppUser)

                            .Include(c => c.Veterinaire).ThenInclude(v => v.AppUser)
                            .Where(c => c.Client.AppUserId == id)
                           .Select(c => new ConsultationCDto
                           {
                               Id = c.Id,
                               Date = c.Date,
                               Diagnostic = c.Diagnostic,
                               Treatment = c.Treatment,
                               Prescription = c.Prescriptions,
                               Notes = c.Notes,
                               VeterinaireName = c.Veterinaire.AppUser.UserName,
                               DocumentPath = c.DocumentPath,
                               Veterinaire = c.Veterinaire.AppUser,
                               CreatedAt = c.CreatedAt,
                               UpdatedAt = c.UpdatedAt,
                               
                           })
                           .ToListAsync();

            return consultations;
        }
    }
}
