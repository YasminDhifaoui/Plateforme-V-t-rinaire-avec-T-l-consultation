using backend.Data;
using backend.Dtos.AdminDtos.AdminDtos;
using backend.Dtos.ClientDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo
{
    public class AdminRepo : IAdminRepo
    {
        private readonly AppDbContext _context;

        public AdminRepo(AppDbContext context)
        {
            _context = context;
        }

     

        //Get Users By Role
        public async Task<IEnumerable<AdminDto>> GetAdmins()

        {
            var admins =await _context.Users
                .Where(user => user.Role == "Admin")
                .Select(user => new AdminDto
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
            return admins;

        }
        //GetAdminById
        public async Task<AdminDto> GetAdminById(Guid id)
        {
            var admin = await _context.Users
                .Where(user => user.Id == id)
                .Select(user => new AdminDto
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
                })
                .FirstOrDefaultAsync();

            return admin;
        }

        //getAdminByUsername
        public async Task<AdminDto> GetAdminByUsername(string username)
        {
            var admin = await _context.Users
                .Where(user => user.UserName == username)
                .Select(user => new AdminDto
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
                })
                .FirstOrDefaultAsync();

            return admin;
        }

        // Update admin
        public async Task<string> UpdateAdmin(Guid userId, UpdateAdminDto updatedAdmin)
        {

            var adminExist =await GetAdminById(userId);
            if (adminExist == null)
            {
                return "Admin not found";
            }
            var userToUpdate =await _context.Users.FindAsync(userId);

            if (userToUpdate == null)
                return "User not found !";

            userToUpdate.UserName = updatedAdmin.Username;
            userToUpdate.Email = updatedAdmin.Email;
            userToUpdate.PhoneNumber = updatedAdmin.PhoneNumber;
            userToUpdate.TwoFactorEnabled = updatedAdmin.TwoFactorEnabled;
            userToUpdate.LockoutEnabled = updatedAdmin.LockoutEnabled;
            userToUpdate.LockoutEnd = updatedAdmin.LockoutEnd;
            userToUpdate.EmailConfirmed = updatedAdmin.EmailConfirmed;
            userToUpdate.PhoneNumberConfirmed = updatedAdmin.PhoneConfirmed;
            userToUpdate.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(userToUpdate);
            SaveChangesAsync();
            return "User updated successfully";
        }

        // Delete admin by Id
        public async Task<string> DeleteAdmin(Guid id)
        {
            var admin = await _context.admins.FirstOrDefaultAsync(v => v.AppUserId == id);

            if (admin == null)
            {
                return "Admin not found";
            }
            _context.admins.Remove(admin);
            SaveChangesAsync();
            return "Admin deleted successfully";
        }


        //Add Admin
        public async Task<string> AddAdmin(Admin admin)
        {
            _context.admins.Add(admin);
            SaveChangesAsync();
            return "Admin added successfully";

        }


        public async Task SaveChangesAsync()
        {
            _context.SaveChangesAsync();
        }
    }
}
