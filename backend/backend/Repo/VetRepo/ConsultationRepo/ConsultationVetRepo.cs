using backend.Data;
using backend.Dtos.VetDtos.ConsultationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.ConsultationRepo
{
    public class ConsultationVetRepo : IConsultationVetRepo
    {
        private readonly AppDbContext _context;

        public ConsultationVetRepo(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ConsultationVetDto>> GetConsultations(Guid vetId)
        {
            return await _context.Consultations
                .Include(c => c.RendezVous).ThenInclude(r => r.Animal).ThenInclude(a => a.Owner)
                .Where(c => c.VeterinaireId == vetId)
                .Select(c => new ConsultationVetDto
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
                    RendezVousID = c.RendezVousId,
                    ClientName = c.Animal.Owner.UserName,
                    AnimalId = c.AnimalId,
                    AnimalName = c.Animal.Nom
                }).ToListAsync();
        }

        public async Task<ConsultationVetDto> AddConsultation(AddConsultationVetDto dto, Guid vetId)
        {
            var rendezVous = await _context.RendezVous
                .Include(rv => rv.Animal).ThenInclude(a => a.Owner)
                .FirstOrDefaultAsync(rv => rv.Id == dto.RendezVousID && rv.VeterinaireId == vetId);

            if (rendezVous == null)
                throw new UnauthorizedAccessException("Rendez-vous not found or doesn't belong to you.");

            string documentPath = null;
            var now = DateTime.UtcNow;
            var folderName = now.ToString("yyyyMMdd_HHmmss");

            if (dto.Document != null && dto.Document.Length > 0)
            {
                var uploadDir = Path.Combine("wwwroot", "docs", rendezVous.AnimalId.ToString(), folderName);
                Directory.CreateDirectory(uploadDir);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadDir, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await dto.Document.CopyToAsync(stream);

                documentPath = Path.Combine("docs", rendezVous.AnimalId.ToString(), folderName, fileName);
            }

            var consultation = new Consultation
            {
                Id = Guid.NewGuid(),
                RendezVousId = dto.RendezVousID,
                Diagnostic = dto.Diagnostic,
                Treatment = dto.Treatment,
                Prescriptions = dto.Prescription,
                Notes = dto.Notes,
                DocumentPath = documentPath,
                CreatedAt = now,
                UpdatedAt = now,
                VeterinaireId = vetId,
                AnimalId = rendezVous.AnimalId,
                Date = dto.Date
            };

            await _context.Consultations.AddAsync(consultation);
            saveChanges();

            return new ConsultationVetDto
            {
                Id = consultation.Id,
                RendezVousID = consultation.RendezVousId,
                Diagnostic = consultation.Diagnostic,
                Treatment = consultation.Treatment,
                Prescription = consultation.Prescriptions,
                Notes = consultation.Notes,
                DocumentPath = consultation.DocumentPath,
                CreatedAt = consultation.CreatedAt,
                UpdatedAt = consultation.UpdatedAt,
                ClientName = rendezVous.Animal.Owner.UserName,
                AnimalId = consultation.AnimalId,
                Date = consultation.Date
            };
        }

        public async Task<bool> UpdateConsultation(Guid consultationId, UpdateConsultationVetDto dto, Guid vetId)
        {
            var consultation = await _context.Consultations
                .FirstOrDefaultAsync(c => c.Id == consultationId && c.VeterinaireId == vetId);

            if (consultation == null) return false;

            consultation.Diagnostic = dto.Diagnostic;
            consultation.Treatment = dto.Treatment;
            consultation.Prescriptions = dto.Prescription;
            consultation.Notes = dto.Notes;
            consultation.RendezVousId = dto.RendezVousID;
            consultation.UpdatedAt = DateTime.UtcNow;

            if (dto.Document != null && dto.Document.Length > 0)
            {
                if (!string.IsNullOrEmpty(consultation.DocumentPath))
                {
                    var oldFolder = Path.Combine("wwwroot", Path.GetDirectoryName(consultation.DocumentPath));
                    if (Directory.Exists(oldFolder))
                        Directory.Delete(oldFolder, true);
                }

                var newFolder = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
                var uploadsFolder = Path.Combine("wwwroot", "docs", consultation.AnimalId.ToString(), newFolder);
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await dto.Document.CopyToAsync(stream);

                consultation.DocumentPath = Path.Combine("docs", consultation.AnimalId.ToString(), newFolder, fileName);
            }

            _context.Consultations.Update(consultation);
            saveChanges();
            return true;
        }

        public async Task<bool> DeleteConsultation(Guid consultationId, Guid vetId)
        {
            var consultation = await _context.Consultations.FirstOrDefaultAsync(c => c.Id == consultationId && c.VeterinaireId == vetId);
            if (consultation == null) return false;

            if (!string.IsNullOrEmpty(consultation.DocumentPath))
            {
                var folderPath = Path.Combine("wwwroot", Path.GetDirectoryName(consultation.DocumentPath));
                if (Directory.Exists(folderPath))
                    Directory.Delete(folderPath, true);
            }

            _context.Consultations.Remove(consultation);
            saveChanges();
            return true;
        }

        public void saveChanges()
        {
            _context.SaveChanges();
        }
    }
}
