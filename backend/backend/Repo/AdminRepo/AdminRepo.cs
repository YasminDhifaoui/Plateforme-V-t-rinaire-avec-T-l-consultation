using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminDtos.UsersDto;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;

namespace backend.Repo.AdminRepo
{
    public class AdminRepo : IAdminRepo
    {
        private readonly AppDbContext _context;

        public AdminRepo(AppDbContext context)
        {
            _context = context;
        }
        //Authentification
        public string AdminRegister(Admin admin)
        {

            _context.admins.Add(admin);
            _context.SaveChanges();

            return "Admin added successfully";
        }

        //UsersList
        public IEnumerable<UserDto> GetAllUsers()
        {
            return _context.Users
                .Select(user => new UserDto
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
                .ToList();
        }

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
