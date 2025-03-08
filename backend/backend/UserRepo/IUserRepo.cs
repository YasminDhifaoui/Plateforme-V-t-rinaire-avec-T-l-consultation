using backend.Dtos;
using backend.Models;
using System.Collections.Generic;

namespace backend.Data
{
    public interface IUserRepo
    {
        IEnumerable<UserDto> GetUsers();

        UserDto GetUserById(Guid id);

        UserDto GetUserByUsername(string username);

      
        UserRegisterDto Register(User user);
        UserLoginDto Login(string username, string password);
        bool ResetPassword(Guid userId, string newPassword); 

      
        void UpdateUser(UserDto user, UserDto updatedUser);
        void DeleteUser(Guid id);

        void SaveChanges();
    }
}
