using backend.Data;
using backend.Dtos.VetDtos.ConsultationDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic;

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
            var vet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUserId == vetId);
            return await _context.Consultations
        //.Include(c => c.Client).ThenInclude(cl => cl.AppUser)
        .Where(c => c.VeterinaireId == vet.VeterinaireId )
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


        public async Task<ConsultationVetDto> AddConsultation(AddConsultationVetDto dto, Guid vetAppUserIdFromToken) // Renamed for clarity
        {

            Console.WriteLine($"DEBUG: Entering AddConsultation method.");
            Console.WriteLine($"DEBUG: vetAppUserIdFromToken (from token): {vetAppUserIdFromToken}");

            var client = await _context.clients
                .FirstOrDefaultAsync(c=>c.AppUserId==dto.ClientId); 

            if (client == null)
            {
                Console.WriteLine("ERROR: Client not found for the given ClientId.");


                throw new ArgumentException("Client not found for the given ClientId.");
            }
            Console.WriteLine($"DEBUG: Found client with AppUserId: {client.AppUserId}");



            var vetEntity = await _context.veterinaires
               .FirstOrDefaultAsync(v => v.AppUserId == vetAppUserIdFromToken);

            if (vetEntity == null)
            {
                Console.WriteLine($"ERROR: Veterinarian with AppUserId '{vetAppUserIdFromToken}' not found.");

                throw new ArgumentException($"Veterinarian with AppUserId '{vetAppUserIdFromToken}' not found.");
            }
            Console.WriteLine($"DEBUG: Found vetEntity.AppUserId: {vetEntity.AppUserId}");
            Console.WriteLine($"DEBUG: Found vetEntity.VeterinaireId (its own PK): {vetEntity.VeterinaireId}");


            string documentPath = null;
            var now = DateTime.UtcNow;
            var folderName = now.ToString("yyyyMMdd_HHmmss");

            if (dto.Document != null && dto.Document.Length > 0)
            {
                var safeFileName = Path.GetFileName(dto.Document.FileName);
                var uploadDir = Path.Combine("wwwroot", "docs", client.AppUserId.ToString(), folderName); 
                Directory.CreateDirectory(uploadDir);

                var fileName = $"{Guid.NewGuid()}_{safeFileName}"; 
                var filePath = Path.Combine(uploadDir, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await dto.Document.CopyToAsync(stream);

                documentPath = Path.Combine("docs", client.AppUserId.ToString(), folderName, fileName).Replace(Path.DirectorySeparatorChar, '/'); // Use forward slashes for URLs
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
                VeterinaireId = vetEntity.VeterinaireId, 
                ClientId = client.ClientId, 
                Date = dto.Date.ToUniversalTime() 
            };
            try
            {
                Console.WriteLine($"DEBUG: Attempting to add Consultation with VeterinaireId: {consultation.VeterinaireId}");
                await _context.Consultations.AddAsync(consultation);
                await _context.SaveChangesAsync();

                Console.WriteLine($"DEBUG: Successfully saved consultation.");
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException ex)
            {
                Console.WriteLine($"ERROR: DbUpdateException caught: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"ERROR: Inner Exception: {ex.InnerException.Message}");
                    if (ex.InnerException is Npgsql.PostgresException pgEx)
                    {
                        Console.WriteLine($"Postgres Error Code: {pgEx.SqlState}");
                        Console.WriteLine($"Postgres Constraint: {pgEx.ConstraintName}");
                        Console.WriteLine($"Postgres Table: {pgEx.TableName}");
                    }
                }
                throw; // Re-throw to see the full stack trace
            }

           
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
                Date = consultation.Date.ToUniversalTime(),
            };
        }

        public async Task<bool> UpdateConsultation(Guid consultationId, UpdateConsultationVetDto dto, Guid vetId)
        {
            var vet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUser.Id == vetId);
            var consultation = await _context.Consultations
                .Include(c => c.Client)
                .FirstOrDefaultAsync(c => c.Id == consultationId && c.VeterinaireId == vet.VeterinaireId);

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
            var vet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUserId == vetId);
            var consultation = await _context.Consultations.FirstOrDefaultAsync(c => c.Id == consultationId && c.VeterinaireId == vet.VeterinaireId);
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
