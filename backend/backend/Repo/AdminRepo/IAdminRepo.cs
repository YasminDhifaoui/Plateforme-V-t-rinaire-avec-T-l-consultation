using backend.Dtos;
using backend.Dtos.AdminDtos.AdminDtos;
using backend.Dtos.ClientDtos;
using backend.Models;
using System.Collections.Generic;

namespace backend.Repo.AdminRepo
{
    public interface IAdminRepo
    {
        Task<IEnumerable<AdminDto>> GetAdmins();

        Task<AdminDto> GetAdminById(Guid id);

        Task<AdminDto> GetAdminByUsername(string username);

        Task<string> UpdateAdmin(Guid userId, UpdateAdminDto updatedAdmin);

        Task<string> DeleteAdmin(Guid id);

        Task<string> AddAdmin(Admin admin);

        Task SaveChangesAsync();
    }
}
