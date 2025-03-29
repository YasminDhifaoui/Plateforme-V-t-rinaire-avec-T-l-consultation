using backend.Dtos;
using backend.Dtos.AdminDtos;
using backend.Dtos.ClientDtos;
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

        IEnumerable<AdminDto> GetAdmins(); 
        AdminDto GetAdminById(Guid id);
        AdminDto GetAdminByUsername(string username);

        string UpdateAdmin(Guid UserId, UpdateAdminDto updatedAdmin);
        string DeleteAdmin(Guid id);
        string AddAdmin(Admin admin);

        void SaveChanges();
    }
}
