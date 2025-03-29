using backend.Dtos.ClientDtos;
using backend.Models;

namespace backend.Repo.ClientsRepo
{
    public interface IClientRepo
    {
        IEnumerable<ClientDto> GetClients();
        ClientDto GetClientById(Guid id);
        ClientDto GetClientByUsername(string username);


        string UpdateClient(Guid UserId, UpdateClientDto updatedUser);
        string DeleteClient(Guid id);
        string AddClient(Client client);  
        void SaveChanges();

    }
}
