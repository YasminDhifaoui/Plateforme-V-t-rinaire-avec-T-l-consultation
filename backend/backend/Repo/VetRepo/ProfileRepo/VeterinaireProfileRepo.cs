using backend.Dtos.VetDtos.ProfileDtos;
using backend.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.ProfileRepo
{
    public class VeterinaireProfileRepo : IVeterinaireProfileRepo
    {
        private readonly UserManager<AppUser> _userManager;

        public VeterinaireProfileRepo(UserManager<AppUser> userManager)
        {
            _userManager = userManager;
        }

        public async Task<VeterinaireProfileDto> GetProfileAsync(Guid userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null) return null;

            return new VeterinaireProfileDto
            {
                Email = user.Email,
                UserName = user.UserName,
                PhoneNumber = user.PhoneNumber,
                FirstName = user.FirstName,
                LastName = user.LastName,
                BirthDate = user.BirthDate,
                Address = user.Address,
                ZipCode = user.ZipCode,
                Gender = user.Gender
            };
        }

        public async Task<bool> UpdateProfileAsync(Guid userId, UpdateVeterinaireProfileDto dto)
        {
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return false;

            user.FirstName = dto.FirstName;
            user.LastName = dto.LastName;
            user.BirthDate = dto.BirthDate.HasValue
                ? DateTime.SpecifyKind(dto.BirthDate.Value, DateTimeKind.Utc)
                : (DateTime?)null;
            user.Address = dto.Address;
            user.ZipCode = dto.ZipCode;
            user.Gender = dto.Gender;

            if (!string.IsNullOrWhiteSpace(dto.UserName)) user.UserName = dto.UserName;
            if (!string.IsNullOrWhiteSpace(dto.PhoneNumber)) user.PhoneNumber = dto.PhoneNumber;

            user.UpdatedAt = DateTime.UtcNow;

            var result = await _userManager.UpdateAsync(user);
            return result.Succeeded;
        }
    }

}
