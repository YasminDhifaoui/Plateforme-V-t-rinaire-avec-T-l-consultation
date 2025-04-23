using backend.Dtos.VetDtos.ClientDtos;

namespace backend.Repo.VetRepo.ClientRepo
{
    public interface IClientVetRepo
    {
        Task<IEnumerable<ClientVetDto>> GetClients(Guid vetId);
    }
}
