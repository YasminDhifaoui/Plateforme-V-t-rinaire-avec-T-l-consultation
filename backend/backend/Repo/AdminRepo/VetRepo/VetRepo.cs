using backend.Data;
using backend.Dtos.AdminDtos.VetDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo.VetRepo
{
    public class VetRepo : IVetRepo
    {
        public readonly AppDbContext _context;
        public VetRepo(AppDbContext context)
        {
            _context = context;
        }

        //get veterinaires
        public async Task<IEnumerable<VetDto>> GetVeterinaires()
        {
            var veterinaires = await _context.Users
                .Where(user => user.Role == "Veterinaire")
                .Select(user => new VetDto
                {
                    Id = user.Id,
                    Username = user.UserName,
                    Email = user.Email,
                    Role = user.Role,
                    PhoneNumber = user.PhoneNumber,

                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt,
                    TwoFactorEnabled = user.TwoFactorEnabled,
                    LockoutEnabled = user.LockoutEnabled,
                    LockoutEnd = (DateTimeOffset)user.LockoutEnd,


                    EmailConfirmed = user.EmailConfirmed,
                    PhoneConfirmed = user.PhoneNumberConfirmed,

                    AccessFailedCount = user.AccessFailedCount
                }).ToListAsync();
            return veterinaires;
        }
        //get vet by id
        public async Task<VetDto> GetVeterinaireById(Guid id)
        {
            var vet = await _context.Users
                .Where(user => user.Id == id)
                .Select(user => new VetDto
                {
                    Id = user.Id,
                    Username = user.UserName,
                    Email = user.Email,
                    Role = user.Role,
                    PhoneNumber = user.PhoneNumber,

                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt,
                    TwoFactorEnabled = user.TwoFactorEnabled,
                    LockoutEnabled = user.LockoutEnabled,
                    LockoutEnd = (DateTimeOffset)user.LockoutEnd,


                    EmailConfirmed = user.EmailConfirmed,
                    PhoneConfirmed = user.PhoneNumberConfirmed,

                    AccessFailedCount = user.AccessFailedCount
                }).FirstOrDefaultAsync();
            return vet;
        }
        //get vet by username
        public async Task<VetDto> GetVeterinaireByUsername(string username)
        {
            var vet = await _context.Users
                .Where(user => user.UserName == username)
                .Select(user => new VetDto
                {
                    Id = user.Id,
                    Username = user.UserName,
                    Email = user.Email,
                    Role = user.Role,
                    PhoneNumber = user.PhoneNumber,

                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt,
                    TwoFactorEnabled = user.TwoFactorEnabled,
                    LockoutEnabled = user.LockoutEnabled,
                    LockoutEnd = (DateTimeOffset)user.LockoutEnd,


                    EmailConfirmed = user.EmailConfirmed,
                    PhoneConfirmed = user.PhoneNumberConfirmed,

                    AccessFailedCount = user.AccessFailedCount
                }).FirstOrDefaultAsync();
            return vet;
        }
        //update vet
        public async Task<string> UpdateVeterinaire(Guid UserId, UpdateVetDto updatedVet)
        {
            var vet =await GetVeterinaireById(UserId);
            if (vet == null)
            {
                return "Veterinaire not found!";
            }
            var userToUpdate = await _context.Users.FindAsync(UserId);

            if (userToUpdate == null)
                return "User not found !";

            userToUpdate.UserName = updatedVet.Username;
            userToUpdate.Email = updatedVet.Email;
            userToUpdate.PasswordHash = updatedVet.Password;
            userToUpdate.Role = updatedVet.Role;
            userToUpdate.PhoneNumber = updatedVet.PhoneNumber;
            userToUpdate.TwoFactorEnabled = updatedVet.TwoFactorEnabled;
            userToUpdate.LockoutEnabled = updatedVet.LockoutEnabled;
            userToUpdate.LockoutEnd = updatedVet.LockoutEnd;
            userToUpdate.EmailConfirmed = updatedVet.EmailConfirmed;
            userToUpdate.PhoneNumberConfirmed = updatedVet.PhoneConfirmed;
            userToUpdate.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(userToUpdate);
            await SaveChanges();
            return "User updated successfully";
        }
        //delete vet
        public async Task<string> DeleteVeterinaire(Guid id)
        {
            var vet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUserId == id);
            if (vet == null)
                return "veterinaire not found !";
            _context.veterinaires.Remove(vet);
            await SaveChanges();
            return "veterinaire deleted successfully";
        }
        //add vet
        public async Task<string> AddVeterinaire(Veterinaire veterinaire)
        {
            await _context.veterinaires.AddAsync(veterinaire);
            await SaveChanges();
            return "Veterinaire added successfully";
        }
        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }


    }
}
