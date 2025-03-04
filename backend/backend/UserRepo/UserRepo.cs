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
                    Username = user.Username,
                    Email = user.Email,
                    Password = user.Password,
                    Role = user.Role
                })
                .ToList();
        }

        //GetUserById
        public UserDto GetUserById(int id)
        {
            var user = _context.Users
                .Where(u => u.Id == id)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Username = u.Username,
                    Email = u.Email,
                    Password = u.Password,
                    Role = u.Role
                })
                .FirstOrDefault();

            return user;
        }

        //getUserByUsername
        public UserDto GetUserByUsername(string username)
        {
            var user = _context.Users
                .Where(u => u.Username == username)
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Username = u.Username,
                    Email = u.Email,
                    Password = u.Password,
                    Role = u.Role
                })
                .FirstOrDefault();

            return user;
        }

        // Register 
        public UserRegisterDto Register(User user)
        {
            _context.Users.Add(user);
            _context.SaveChanges();

            return new UserRegisterDto
            {
                Username = user.Username,
                Email = user.Email, 
                Password = user.Password,
                Role = user.Role
            };
        }

        // Login
        public UserLoginDto Login(string username, string password)
        {
            var user = _context.Users.SingleOrDefault(u => u.Username == username);

            if (user != null && BCrypt.Net.BCrypt.Verify(password, user.Password))
            {
                return new UserLoginDto
                {
                    
                    Username = user.Username,
                    Password = user.Password
                };
            }
            return null; 
        }

        // Reset password 
        public bool ResetPassword(int userId, string newPassword)
        {
            var user = _context.Users.Find(userId);

            if (user != null)
            {
                user.Password = BCrypt.Net.BCrypt.HashPassword(newPassword);
                _context.SaveChanges();
                return true;
            }

            return false;
        }

        // Update user 
        public void UpdateUser(UserDto user,UserDto updatedUser)
        {
            var userc = _context.Users.Find(user.Id);

            if (userc != null)
            {
                userc.Username = updatedUser.Username;
                userc.Email = updatedUser.Email;
                userc.Role = updatedUser.Role;

                _context.Users.Update(userc);
                _context.SaveChanges();
            }
        }

        // Delete user by Id
        public void DeleteUser(int id)
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
