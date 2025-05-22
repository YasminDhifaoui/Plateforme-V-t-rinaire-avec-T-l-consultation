
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
                            .Include(r => r.Client).ThenInclude(cl => cl.AppUser) // Then include the AppUser object related to that Client

                            .Include(c => c.Veterinaire)

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
                               
                           })
                           .ToListAsync();

            return consultations;
        }
    }
}
