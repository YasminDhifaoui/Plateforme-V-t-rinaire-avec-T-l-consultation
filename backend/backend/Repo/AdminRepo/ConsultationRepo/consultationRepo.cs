using backend.Data;
using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Models;
using Microsoft.AspNetCore.Http.HttpResults;
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
            string documentPath = null;
            var rdv = await _context.RendezVous.FindAsync(dto.RendezVousID);
           
            var consultationDate = DateTime.UtcNow;
            var formattedDate = consultationDate.ToString("yyyyMMdd_HHmmss"); 

            if (dto.Document != null && dto.Document.Length > 0)
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "docs", rdv.AnimalId.ToString(), formattedDate);
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Document.CopyToAsync(stream);
                }

                documentPath = Path.Combine("docs", rdv.AnimalId.ToString(), formattedDate, fileName);
            }

            var consultation = new Consultation
            {
                Id = Guid.NewGuid(),
                Date = dto.Date,
                RendezVousId = dto.RendezVousID,
                Diagnostic = dto.Diagnostic,
                Treatment = dto.Treatment,
                Prescriptions = dto.Prescription,
                Notes = dto.Notes,
                DocumentPath = documentPath,
                VeterinaireId = rdv.VeterinaireId,
                AnimalId = rdv.AnimalId,
                CreatedAt = consultationDate,
                UpdatedAt = consultationDate
            };

            await _context.Consultations.AddAsync(consultation);
            await saveChanges();
            return consultation;
        }

        public async Task<string> UpdateAsync(Guid id, UpdateConsultationDto dto)
        {
            var consultation = await _context.Consultations.FindAsync(id);
            if (consultation == null)
                return "Consultation not found";

            var rdv =await _context.RendezVous.FindAsync(dto.RendezVousID);
            if (rdv == null) return "rendez vous not found!";

            consultation.Date = dto.Date.ToUniversalTime();
            consultation.Diagnostic = dto.Diagnostic;
            consultation.Treatment = dto.Treatment;
            consultation.Prescriptions = dto.Prescription;
            consultation.Notes = dto.Notes;
            consultation.RendezVousId = dto.RendezVousID;
            consultation.AnimalId = rdv.AnimalId;
            consultation.VeterinaireId = rdv.VeterinaireId;
            consultation.UpdatedAt = DateTime.UtcNow;

            if (dto.Document != null && dto.Document.Length > 0)
            {
                if (!string.IsNullOrEmpty(consultation.DocumentPath))
                {
                    var oldFolderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", Path.GetDirectoryName(consultation.DocumentPath));
                    if (Directory.Exists(oldFolderPath))
                    {
                        Directory.Delete(oldFolderPath, true);
                    }
                }

                var newDateFolder = dto.Date.ToString("yyyyMMdd_HHmmss");
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "docs", consultation.AnimalId.ToString(), newDateFolder);
                Directory.CreateDirectory(uploadsFolder);

                var fileName = $"{Guid.NewGuid()}_{dto.Document.FileName}";
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Document.CopyToAsync(stream);
                }

                consultation.DocumentPath = Path.Combine("docs", consultation.AnimalId.ToString(), newDateFolder, fileName);
            }

            _context.Consultations.Update(consultation);
            await saveChanges();
            return "Consultation updated";
        }




        public async Task<string> DeleteAsync(Guid id)
        {
            var consultation = await _context.Consultations.FirstOrDefaultAsync(c => c.Id == id);
            if (consultation == null)
                return "Consultation not found";

            if (!string.IsNullOrEmpty(consultation.DocumentPath))
            {
                var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", Path.GetDirectoryName(consultation.DocumentPath));
                if (Directory.Exists(folderPath))
                {
                    Directory.Delete(folderPath, true); 
                }
            }

            _context.Consultations.Remove(consultation);
            await saveChanges();

            return "Consultation deleted";
        }

        public async Task saveChanges()
            {
                await _context.SaveChangesAsync();
            }
        }
    }


