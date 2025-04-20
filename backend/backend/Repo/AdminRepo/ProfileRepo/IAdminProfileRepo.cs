
using backend.Dtos.AdminDtos.ProfileDtos;

namespace backend.Repo.AdminRepo.ProfileRepo
{
    public interface IAdminProfileRepo
    {
        Task<AdminProfileDto> GetProfileAsync(Guid userId);
        Task<bool> UpdateProfileAsync(Guid userId, UpdateAdminProfileDto dto);
    }
}
