using backend.Data;
using backend.Dtos.VetDtos.ClientDtos;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.ClientRepo
{
    public class ClientVetRepo : IClientVetRepo
    {
        public readonly AppDbContext _context;
        public ClientVetRepo(AppDbContext context) {
            _context = context;
        }
        public async Task<IEnumerable<ClientVetDto>> GetClients(Guid vetId)
        {
            var clients = await _context.Users
                .Where(user => user.Role == "Client" &&
                               _context.RendezVous
                                   .Any(rdv => rdv.VeterinaireId == vetId && rdv.ClientId == user.Id))
                .Select(user => new ClientVetDto
                {
                    Id = user.Id,
                    Username = user.UserName,
                    Address = user.Address,
                    Email = user.Email,
                    PhoneNumber = user.PhoneNumber
                })
                .ToListAsync();

            return clients;
        }

    }
}
