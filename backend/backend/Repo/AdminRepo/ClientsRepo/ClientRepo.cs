using backend.Data;
using backend.Dtos.AdminDtos.ClientDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo.ClientsRepo
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
            var clients = _context.Users
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
            return clients;

        }
        //GetClientById
        public ClientDto GetClientById(Guid id)
        {
            var client = _context.Users
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

            return client;
        }

        //getClientByUsername
        public ClientDto GetClientByUsername(string username)
        {
            var client = _context.Users
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

            return client;
        }

        // Update client 
        public string UpdateClient(Guid UserId, UpdateClientDto updatedUser)
        {

            var clientExist = GetClientById(UserId);
            if (clientExist == null)
            {
                return "Client not found";
            }
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
            SaveChanges();
            return "User updated successfully";
        }

        // Delete client by Id
        public string DeleteClient(Guid id)
        {
            var client = _context.clients.Find(id);
            if (client == null)
            {
                return "Client not found";
            }
            _context.clients.Remove(client);
            SaveChanges();
            return "Client deleted successfully";
        }


        //Add client 
        public string AddClient(Client client)
        {
            _context.clients.Add(client);
            SaveChanges();

            return "Client added successfully";

        }


        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
