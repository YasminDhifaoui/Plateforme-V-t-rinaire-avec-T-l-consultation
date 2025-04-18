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
        public async Task<IEnumerable<ClientDto>> GetClientsAsync()
        {
            var clients =await _context.Users
                .Where(user => user.Role == "Client")
                .Select(user => new ClientDto
                {
                    Id = user.Id,
                    Username = user.UserName!,
                    Email = user.Email!,
                    Role = user.Role,
                    PhoneNumber = user.PhoneNumber!,

                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt,
                    TwoFactorEnabled = user.TwoFactorEnabled,
                    LockoutEnabled = user.LockoutEnabled,
                    LockoutEnd = (DateTimeOffset)user.LockoutEnd!,


                    EmailConfirmed = user.EmailConfirmed,
                    PhoneConfirmed = user.PhoneNumberConfirmed,

                    AccessFailedCount = user.AccessFailedCount
                }).ToListAsync();
            return clients;

        }
        //GetClientById
        public async Task<ClientDto> GetClientByIdAsync(Guid id)
        {
            var client = await _context.Users
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
                .FirstOrDefaultAsync();

            return client;
        }

        //getClientByUsername
        public async Task<ClientDto> GetClientByUsernameAsync(string username)
        {
            var client = await _context.Users
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
                    LockoutEnd = user.LockoutEnd.HasValue ? user.LockoutEnd.Value : DateTimeOffset.MaxValue,


                    EmailConfirmed = user.EmailConfirmed,
                    PhoneConfirmed = user.PhoneNumberConfirmed,

                    AccessFailedCount = user.AccessFailedCount
                })
                .FirstOrDefaultAsync();

            return client;
        }

        // Update client 
        public async Task<string> UpdateClientAsync(Guid userId, UpdateClientDto updatedUser)
        {

            var clientExist = await GetClientByIdAsync(userId);
            if (clientExist == null)
            {
                return "Client not found";
            }
            var userToUpdate = _context.Users.Find(userId);

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
            SaveChangesAsync();
            return "User updated successfully";
        }

        // Delete client by Id
        public async Task<string> DeleteClientAsync(Guid id)
        {
            var client = await _context.clients.FirstOrDefaultAsync(v => v.AppUserId == id);

            if (client == null)
            {
                return "Client not found";
            }
            _context.clients.Remove(client);
            SaveChangesAsync();
            return "Client deleted successfully";
        }


        //Add client 
        public async Task<string> AddClientAsync(Client client)
        {
            _context.clients.Add(client);
            SaveChangesAsync();

            return "Client added successfully";

        }


        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
