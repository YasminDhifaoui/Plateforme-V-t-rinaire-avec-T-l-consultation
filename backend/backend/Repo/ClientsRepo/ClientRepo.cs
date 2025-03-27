using backend.Data;
using backend.Dtos.ClientDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientsRepo
{
    public class ClientRepo : IClientRepo
    {
        private readonly AppDbContext _context;

        public ClientRepo(AppDbContext context)
        {
            _context = context;
        }

        //Get Users By Role
        public IEnumerable<ClientDto> GetClients()
        {
            var user = _context.Users
                .Where(user => user.Role == "Client")
                .Select(user => new ClientDto
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
        public ClientDto GetClientById(Guid id)
        {
            var user = _context.Users
                .Where(user => user.Id == id)
                .Select(user => new ClientDto
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
        public ClientDto GetClientByUsername(string username)
        {
            var user = _context.Users
                .Where(user => user.UserName == username)
                .Select(user => new ClientDto
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
        public string UpdateClient(Guid UserId, UpdateClientDto updatedUser)
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
            userToUpdate.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(userToUpdate);
            _context.SaveChanges();
            return "User updated successfully";
        }

        // Delete user by Id
        public string DeleteClient(Guid id)
        {
            var user = _context.Users.Find(id);
            if (user == null)
                return "User not found!";
            _context.Users.Remove(user);
            _context.SaveChanges();
            return "User deleted successfully";
        }

         
         //Add user 
         public string AddClient (Client client)
         {
            _context.clients.Add(client);
            _context.SaveChanges();

            return "Client added successfully";
        
         }
        

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
