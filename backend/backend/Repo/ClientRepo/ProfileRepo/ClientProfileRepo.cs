using backend.Data;
using backend.Dtos.ClientDtos.ProfileDtos;
using backend.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.ProfileRepo
{
    public class ClientProfileRepo : IClientProfileRepo
    {
        private readonly UserManager<AppUser> _userManager;
        private readonly AppDbContext _context;

        public ClientProfileRepo(UserManager<AppUser> userManager, AppDbContext context)
        {
            _userManager = userManager;
            _context = context;
        }

        public async Task<ClientProfileDto> GetProfileAsync(Guid userId)
        {
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) throw new Exception("User not found");

            var animals = await _context.Animals
                .Where(a => a.OwnerId == userId)
                .Select(a => a.Nom)
                .ToListAsync();

            return new ClientProfileDto
            {   
                Email = user.Email,
                UserName = user.UserName,
                PhoneNumber = user.PhoneNumber,
                FirstName = user.FirstName,
                LastName = user.LastName,
                BirthDate = user.BirthDate,
                Address = user.Address,
                ZipCode = user.ZipCode,
                Gender = user.Gender,
                AnimalNames = animals
            };
        }

        public async Task<bool> UpdateProfileAsync(Guid userId, UpdateClientProfileDto dto)
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
