using backend.Dtos.ClientDtos.VetDtos;

namespace backend.Repo.ClientRepo.VetRepo
{
    public interface IVetCRepo
    {
        Task<IEnumerable<VetCDto>> GetAvailableVets();
    }
}
