using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminUsersDto;
using backend.Dtos.UsersDto;
using backend.Models;
using System.Collections.Generic;

namespace backend.Repo.AdminRepo
{
    public interface IAdminRepo
    {
        /*
         Admin controllers:
            authcontroller: register/login/confirmEmail/TokenJwt
            adminController:crud (not sure)
            ClientController: crud
            VetController: crud
            ApplicationController
         */

        //Authentification:
        string AdminRegister(Admin admin);

        /*AdminLoginDto AdminLogin(string username, string password);
        bool AdminResetPassword(Guid userId, string newPassword);*/

        //AdminUsers Controller:
        IEnumerable<UserDto> GetAllUsers(); 

        IEnumerable<UserDto> GetUsersByRole(string role);
        UserDto GetUserById(Guid id);
        UserDto GetUserByUsername(string username);


        string UpdateUser(Guid UserId, UserUpdateDto updatedUser);
        string DeleteUser(Guid id);

        //string AddUser(UserDto user);  

        void SaveChanges();
    }
}
