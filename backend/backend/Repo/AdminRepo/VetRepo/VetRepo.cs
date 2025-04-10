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
        public IEnumerable<VetDto> GetVeterinaires()
        {
            var veterinaires = _context.Users
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
                }).ToList();
            return veterinaires;
        }
        //get vet by id
        public VetDto GetVeterinaireById(Guid id)
        {
            var vet = _context.Users
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
                }).FirstOrDefault();
            return vet;
        }
        //get vet by username
        public VetDto GetVeterinaireByUsername(string username)
        {
            var vet = _context.Users
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
                }).FirstOrDefault();
            return vet;
        }
        //update vet
        public string UpdateVeterinaire(Guid UserId, UpdateVetDto updatedVet)
        {
            var vet = GetVeterinaireById(UserId);
            if (vet == null)
            {
                return "Veterinaire not found!";
            }
            var userToUpdate = _context.Users.Find(UserId);

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
            SaveChanges();
            return "User updated successfully";
        }
        //delete vet
        public string DeleteVeterinaire(Guid id)
        {
            var vet = _context.veterinaires.Find(id);
            if (vet == null)
                return "veterinaire not found !";
            _context.veterinaires.Remove(vet);
            SaveChanges();
            return "veterinaire deleted successfully";
        }
        //add vet
        public string AddVeterinaire(Veterinaire veterinaire)
        {
            _context.veterinaires.Add(veterinaire);
            SaveChanges();
            return "Veterinaire added successfully";
        }
        public void SaveChanges()
        {
            _context.SaveChanges();
        }


    }
}
