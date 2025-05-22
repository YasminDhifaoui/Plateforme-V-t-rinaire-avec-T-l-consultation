using backend.Dtos.VetDtos.ClientDtos;
using backend.Models;

namespace backend.Repo.VetRepo.ClientRepo
{
    public interface IClientVetRepo
    {
        Task<IEnumerable<ClientVetDto>> GetClients(Guid vetId);
        Task<AppUser> GetClientById(Guid clientId);

    }
}
