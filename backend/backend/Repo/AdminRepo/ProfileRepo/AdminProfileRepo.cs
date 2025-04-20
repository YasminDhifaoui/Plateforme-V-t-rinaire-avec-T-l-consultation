using backend.Dtos.AdminDtos.ProfileDtos;
using backend.Dtos.VetDtos.ProfileDtos;
using backend.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.AdminRepo.ProfileRepo
{
    public class AdminProfileRepo : IAdminProfileRepo
    {
        private readonly UserManager<AppUser> _userManager;

        public AdminProfileRepo (UserManager<AppUser> userManager)
        {
            _userManager = userManager;
        }
        public async Task<AdminProfileDto> GetProfileAsync(Guid userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null) return null;

            return new AdminProfileDto
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

        public async Task<bool> UpdateProfileAsync(Guid userId, UpdateAdminProfileDto dto)
        {
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return false;

            user.FirstName = dto.FirstName;
            user.LastName = dto.LastName;
            user.BirthDate = dto.BirthDate;
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
