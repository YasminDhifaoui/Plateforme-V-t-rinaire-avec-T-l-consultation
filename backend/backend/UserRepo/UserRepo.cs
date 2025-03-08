using backend.Dtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;

namespace backend.Data
{
    public class UserRepo : IUserRepo
    {
        private readonly AppDbContext _context;

        public UserRepo(AppDbContext context)
        {
            _context = context;
        }

        //UsersList
        public IEnumerable<UserDto> GetUsers()
        {
            return _context.Users
                .Select(user => new UserDto
                {
                    Id = user.Id,  
                    Username = user.UserName,
                    Email = user.Email,
                    Password = user.PasswordHash, 
                    Role = user.Role
                })
                .ToList();
        }

        //GetUserById
        public UserDto GetUserById(Guid id)  
        {
            var user = _context.Users
                .Where(u => u.Id == id)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Username = u.UserName,
                    Email = u.Email,
                    Password = u.PasswordHash,  
                    Role = u.Role
                })
                .FirstOrDefault();

            return user;
        }

        //getUserByUsername
        public UserDto GetUserByUsername(string username)
        {
            var user = _context.Users
                .Where(u => u.UserName == username)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Username = u.UserName,
                    Email = u.Email,
                    Password = u.PasswordHash,  
                    Role = u.Role
                })
                .FirstOrDefault();

            return user;
        }

        // Register 
        public UserRegisterDto Register(User user)
        {
            
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(user.PasswordHash);

            _context.Users.Add(user);
            _context.SaveChanges();

            return new UserRegisterDto
            {
                Username = user.UserName,
                Email = user.Email,
                Password = user.PasswordHash,  
                Role = user.Role
            };
        }

        // Login
        public UserLoginDto Login(string username, string password)
        {
            var user = _context.Users.SingleOrDefault(u => u.UserName == username);

            if (user != null && BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            {
                return new UserLoginDto
                {
                    Username = user.UserName,
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
        public void UpdateUser(UserDto user, UserDto updatedUser)
        {
            var userToUpdate = _context.Users.Find(user.Id);

            if (userToUpdate != null)
            {
                userToUpdate.UserName = updatedUser.Username;
                userToUpdate.Email = updatedUser.Email;
                userToUpdate.Role = updatedUser.Role;

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
