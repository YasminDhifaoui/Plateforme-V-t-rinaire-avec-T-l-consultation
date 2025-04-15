using backend.Data;
using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo.ConsultationRepo
{
    public class consultationRepo : IConsultationRepo
    {
            public readonly AppDbContext _context;

            public consultationRepo(AppDbContext context)
            {
                _context = context;
            }

            public async Task<IEnumerable<Consultation>> GetAllConsultations()
            {
                return await _context.Consultations.ToListAsync();

        }

        public async Task<Consultation> GetConsultationById(Guid id)
            {
                return await _context.Consultations
                    .Include(c => c.RendezVous)
                    .ThenInclude(r => r.Animal)
                    .Include(c => c.Veterinaire)
                    .FirstOrDefaultAsync(c => c.Id == id);
            }

            public async Task<Consultation> AddConsultation(AddConsultationDto dto)
            {
                var rendezVous = await _context.RendezVous.FindAsync(dto.RendezVousID);
                if (rendezVous == null) return null;

                var consultation = new Consultation
                {
                    Id = Guid.NewGuid(),
                    Date = dto.Date,
                    Diagnostic = dto.Diagnostic,
                    Treatment = dto.Treatment,
                    Prescriptions = dto.Prescription,
                    Notes = dto.Notes,
                    DocumentPath = dto.DocumentPath,
                    RendezVousId = dto.RendezVousID,
                    AnimalId = rendezVous.AnimalId,
                    VeterinaireId = rendezVous.VeterinaireId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Consultations.Add(consultation);
                await _context.SaveChangesAsync();
                return consultation;
            }

            public string UpdateAsync(Guid id, UpdateConsultationDto dto)
            {
                var consultation = _context.Consultations.Find(id);
                if (consultation == null) return "Consultation not found";

                consultation.Date = dto.Date;
                consultation.Diagnostic = dto.Diagnostic;
                consultation.Treatment = dto.Treatment;
                consultation.Prescriptions = dto.Prescription;
                consultation.Notes = dto.Notes;
                consultation.DocumentPath = dto.DocumentPath;
                consultation.UpdatedAt = DateTime.UtcNow;

                _context.Consultations.Update(consultation);
                _context.SaveChanges();
                return "Consultation updated";
            }

            public string DeleteAsync(Guid id)
            {
                var consultation = _context.Consultations.FirstOrDefault(c => c.Id.ToString().Equals(id.ToString()));
                if (consultation == null) return "Consultation not found";

                _context.Consultations.Remove(consultation);
                _context.SaveChanges();
                return "Consultation deleted";
            }

            public void saveChanges()
            {
                _context.SaveChanges();
            }
        }
    }


