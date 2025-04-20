using backend.Dtos.ClientDtos.ProfileDtos;

namespace backend.Repo.ClientRepo.ProfileRepo
{
    public interface IClientProfileRepo
    {
        Task<ClientProfileDto> GetProfileAsync(Guid userId);
        Task<bool> UpdateProfileAsync(Guid userId, UpdateClientProfileDto dto);
   
    }
}
