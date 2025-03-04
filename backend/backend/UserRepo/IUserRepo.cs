using backend.Dtos;
using backend.Models;
using System.Collections.Generic;

namespace backend.Data
{
    public interface IUserRepo
    {
        IEnumerable<UserDto> GetUsers();
        UserDto GetUserById(int id);
        UserDto GetUserByUsername(string username);

        // User Management
        UserRegisterDto Register(User user);
        UserLoginDto Login(string username, string password);
        bool ResetPassword(int userId, string newPassword);

        // CRUD 
        void UpdateUser(UserDto user,UserDto updatedUser);
        void DeleteUser(int id);

        void SaveChanges();
    }
}
