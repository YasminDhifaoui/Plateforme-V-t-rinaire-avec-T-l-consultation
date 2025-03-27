using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminDtos.UsersDto;
using backend.Models;
using System.Collections.Generic;

namespace backend.Repo.AdminRepo
{
    public interface IAdminRepo
    {
        /*
         Admin controllers:
            authcontroller: register/login/confirmEmail/TokenJwt
            adminController:crud 
            ClientController: crud
            VetController: crud
            ApplicationController
         */

        //Authentification:
        string AdminRegister(Admin admin);

        //AdminUsers Controller:
        IEnumerable<UserDto> GetAllUsers(); 
       
        void SaveChanges();
    }
}
