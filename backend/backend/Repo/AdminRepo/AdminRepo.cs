using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminUsersDto;
using backend.Dtos.UsersDto;
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
        //Get Users By Role
        public IEnumerable <UserDto> GetUsersByRole(string Role) 
        {
            var user = _context.Users
                .Where(user => user.Role == Role)
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
                }).ToList();
            return user;

        }
        //GetUserById
        public UserDto GetUserById(Guid id)
        {
            var user = _context.Users
                .Where(user => user.Id == id)
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
                .FirstOrDefault();

            return user;
        }

        //getUserByUsername
        public UserDto GetUserByUsername(string username)
        {
            var user = _context.Users
                .Where(user => user.UserName == username)
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
                .FirstOrDefault();

            return user;
        }



        // Update user 
        public string UpdateUser(Guid UserId, UserUpdateDto updatedUser)
        {
            var userToUpdate = _context.Users.Find(UserId);

            if (userToUpdate == null)
                return "User not found !";
            
            userToUpdate.UserName = updatedUser.Username;
            userToUpdate.Email = updatedUser.Email;
            userToUpdate.PasswordHash = updatedUser.Password;
            userToUpdate.Role = updatedUser.Role;
            userToUpdate.PhoneNumber = updatedUser.PhoneNumber;
            userToUpdate.TwoFactorEnabled = updatedUser.TwoFactorEnabled;
            userToUpdate.LockoutEnabled = updatedUser.LockoutEnabled;
            userToUpdate.LockoutEnd = updatedUser.LockoutEnd;
            userToUpdate.EmailConfirmed = updatedUser.EmailConfirmed;
            userToUpdate.PhoneNumberConfirmed = updatedUser.PhoneConfirmed;
            userToUpdate.UpdatedAt= DateTime.UtcNow;

            _context.Users.Update(userToUpdate);
            _context.SaveChanges();
            return "User updated successfully";
        }

        // Delete user by Id
        public string DeleteUser(Guid id)
        {
            var user = _context.Users.Find(id);
            if (user == null)
                return "User not found!";
            _context.Users.Remove(user);
            _context.SaveChanges();
            return "User deleted successfully";
        }
        
       /* 
        //Add user 
        public string AddUser (UserDto user)
        {
            var userId = _context.Users.Find(user.Id);
            var userRole = _context.Users.Find(user.Role);
            if (userRole == null || userId==null)
                return "Check Id or role of the user!";
            if (userRole == "Admin")
                _context.admins.Add(user);
            if (userRole == "Client")
                _context.clients.Add(user);
            if (userRole == "Client")
                _context.clients.Add(user);

            return "User added successfully";


        }
       */

       

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
