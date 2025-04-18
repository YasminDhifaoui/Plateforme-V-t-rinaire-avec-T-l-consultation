using backend.Dtos.AdminDtos.ClientDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.ClientsRepo
{
    public interface IClientRepo
    {
        Task<IEnumerable<ClientDto>> GetClientsAsync();
        Task<ClientDto> GetClientByIdAsync(Guid id);
        Task<ClientDto> GetClientByUsernameAsync(string username);
        Task<string> UpdateClientAsync(Guid userId, UpdateClientDto updatedUser);
        Task<string> DeleteClientAsync(Guid id);
        Task<string> AddClientAsync(Client client);
        Task SaveChangesAsync();

    }
}
