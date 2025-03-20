using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
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

        //UsersList
        public IEnumerable<AdminDto> GetUsers()
        {
            return _context.Users
                .Select(user => new AdminDto
                {
                    Id = user.Id,
                    Username = user.UserName,
                    Email = user.Email,
                    Password = user.PasswordHash
                })
                .ToList();
        }

        //GetUserById
        public AdminDto GetUserById(Guid id)
        {
            var user = _context.Users
                .Where(u => u.Id == id)
                .Select(u => new AdminDto
                {
                    Id = u.Id,
                    Username = u.UserName,
                    Email = u.Email,
                    Password = u.PasswordHash
                })
                .FirstOrDefault();

            return user;
        }

        //getUserByUsername
        public AdminDto GetUserByUsername(string username)
        {
            var user = _context.Users
                .Where(u => u.UserName == username)
                .Select(u => new AdminDto
                {
                    Id = u.Id,
                    Username = u.UserName,
                    Email = u.Email,
                    Password = u.PasswordHash
                })
                .FirstOrDefault();

            return user;
        }

        // Register 
        public string RegisterAdmin(Admin admin)
        {

            _context.admins.Add(admin);
            _context.SaveChanges();

            return "Admin added successfully";
        }

        // Login
        public AdminLoginDto Login(string username, string password)
        {
            var user = _context.Users.SingleOrDefault(u => u.UserName == username);

            if (user != null && BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            {
                return new AdminLoginDto
                {
                    Email = user.Email,
                    Password = user.PasswordHash
                };
            }
            return null;
        }

        // Reset password 
        public bool ResetPassword(Guid userId, string newPassword)
        {
            var user = _context.Users.Find(userId);

            if (user != null)
            {
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
                _context.SaveChanges();
                return true;
            }

            return false;
        }

        // Update user 
        public void UpdateUser(AdminDto user, AdminDto updatedUser)
        {
            var userToUpdate = _context.Users.Find(user.Id);

            if (userToUpdate != null)
            {
                userToUpdate.UserName = updatedUser.Username;
                userToUpdate.Email = updatedUser.Email;

                _context.Users.Update(userToUpdate);
                _context.SaveChanges();
            }
        }

        // Delete user by Id
        public void DeleteUser(Guid id)
        {
            var user = _context.Users.Find(id);
            if (user != null)
            {
                _context.Users.Remove(user);
                _context.SaveChanges();
            }
        }

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
