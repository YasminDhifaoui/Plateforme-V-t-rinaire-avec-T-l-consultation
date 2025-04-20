using backend.Dtos.VetDtos.ProfileDtos;

namespace backend.Repo.VetRepo.ProfileRepo
{
    public interface IVeterinaireProfileRepo
    {
        Task<VeterinaireProfileDto> GetProfileAsync(Guid userId);
        Task<bool> UpdateProfileAsync(Guid userId, UpdateVeterinaireProfileDto dto);
    }
}
