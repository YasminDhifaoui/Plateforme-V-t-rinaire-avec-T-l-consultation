using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Models;
using System.Collections.Generic;

namespace backend.Repo.AdminRepo
{
    public interface IAdminRepo
    {
        IEnumerable<AdminDto> GetUsers();

        AdminDto GetUserById(Guid id);

        AdminDto GetUserByUsername(string username);


        AdminRegisterDto Register(AppUser user);
        AdminLoginDto Login(string username, string password);
        bool ResetPassword(Guid userId, string newPassword);


        void UpdateUser(AdminDto user, AdminDto updatedUser);
        void DeleteUser(Guid id);

        void SaveChanges();
    }
}
