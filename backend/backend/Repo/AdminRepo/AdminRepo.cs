using backend.Data;
using backend.Dtos.AdminDtos;
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
        public IEnumerable<AdminDto> GetAdmins()
        {
            var admins = _context.Users
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
                }).ToList();
            return admins;

        }
        //GetAdminById
        public AdminDto GetAdminById(Guid id)
        {
            var admin = _context.Users
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
                .FirstOrDefault();

            return admin;
        }

        //getAdminByUsername
        public AdminDto GetAdminByUsername(string username)
        {
            var admin = _context.Users
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
                .FirstOrDefault();

            return admin;
        }

        // Update admin
        public string UpdateAdmin(Guid UserId, UpdateAdminDto updatedAdmin)
        {

            var adminExist = this.GetAdminById(UserId);
            if (adminExist == null)
            {
                return "Admin not found";
            }
            var userToUpdate = _context.Users.Find(UserId);

            if (userToUpdate == null)
                return "User not found !";

            userToUpdate.UserName = updatedAdmin.Username;
            userToUpdate.Email = updatedAdmin.Email;
            userToUpdate.PasswordHash = updatedAdmin.Password;
            userToUpdate.Role = updatedAdmin.Role;
            userToUpdate.PhoneNumber = updatedAdmin.PhoneNumber;
            userToUpdate.TwoFactorEnabled = updatedAdmin.TwoFactorEnabled;
            userToUpdate.LockoutEnabled = updatedAdmin.LockoutEnabled;
            userToUpdate.LockoutEnd = updatedAdmin.LockoutEnd;
            userToUpdate.EmailConfirmed = updatedAdmin.EmailConfirmed;
            userToUpdate.PhoneNumberConfirmed = updatedAdmin.PhoneConfirmed;
            userToUpdate.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(userToUpdate);
            this.SaveChanges();
            return "User updated successfully";
        }

        // Delete admin by Id
        public string DeleteAdmin(Guid id)
        {
            var admin = _context.admins.Find(id);
            if (admin == null)
            {
                return "Admin not found";
            }
            _context.admins.Remove(admin);
            this.SaveChanges();
            return "Admin deleted successfully";
        }


        //Add Admin
        public string AddAdmin(Admin admin)
        {
            _context.admins.Add(admin);
            this.SaveChanges();
            return "Admin added successfully";

        }


        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
