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
        //.Include(c => c.Client).ThenInclude(cl => cl.AppUser)
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
                    ClientId = c.ClientId,
                    ClientName = c.Client.AppUser.UserName,
                    CreatedAt = c.CreatedAt,
                    UpdatedAt = c.UpdatedAt,
                })
                .ToListAsync();
        }



        public async Task<ConsultationVetDto> AddConsultation(AddConsultationVetDto dto, Guid vetId)
        {
            var client = await _context.clients
                .FirstOrDefaultAsync(a => a.AppUserId == dto.ClientId);

            if (client == null)
                throw new UnauthorizedAccessException("Client not found.");

            string documentPath = null;
            var now = DateTime.UtcNow;
            var folderName = now.ToString("yyyyMMdd_HHmmss");

            if (dto.Document != null && dto.Document.Length > 0)
            {
                var uploadDir = Path.Combine("wwwroot", "docs", client.AppUserId.ToString(), folderName);
                Directory.CreateDirectory(uploadDir);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadDir, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await dto.Document.CopyToAsync(stream);

                documentPath = Path.Combine("docs", client.AppUserId.ToString(), folderName, fileName);
            }

            var consultation = new Consultation
            {
                Id = Guid.NewGuid(),
                Diagnostic = dto.Diagnostic,
                Treatment = dto.Treatment,
                Prescriptions = dto.Prescription,
                Notes = dto.Notes,
                DocumentPath = documentPath,
                CreatedAt = now,
                UpdatedAt = now,
                VeterinaireId = vetId,
                ClientId = client.ClientId,
                Date = dto.Date.ToUniversalTime()
            };

            await _context.Consultations.AddAsync(consultation);
            saveChanges();

            return new ConsultationVetDto
            {
                Id = consultation.Id,
                Diagnostic = consultation.Diagnostic,
                Treatment = consultation.Treatment,
                Prescription = consultation.Prescriptions,
                Notes = consultation.Notes,
                DocumentPath = consultation.DocumentPath,
                CreatedAt = consultation.CreatedAt,
                UpdatedAt = consultation.UpdatedAt,
                ClientId = consultation.ClientId,
                Date = consultation.Date
            };
        }

        public async Task<bool> UpdateConsultation(Guid consultationId, UpdateConsultationVetDto dto, Guid vetId)
        {
            var consultation = await _context.Consultations
                .Include(c => c.Client)
                .FirstOrDefaultAsync(c => c.Id == consultationId && c.VeterinaireId == vetId);

            if (consultation == null) return false;
            consultation.Date = dto.Date.ToUniversalTime();
            consultation.Diagnostic = dto.Diagnostic;
            consultation.Treatment = dto.Treatment;
            consultation.Prescriptions = dto.Prescription;
            consultation.Notes = dto.Notes;
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
                var uploadsFolder = Path.Combine("wwwroot", "docs", consultation.ClientId.ToString(), newFolder);
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await dto.Document.CopyToAsync(stream);

                consultation.DocumentPath = Path.Combine("docs", consultation.ClientId.ToString(), newFolder, fileName);
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
