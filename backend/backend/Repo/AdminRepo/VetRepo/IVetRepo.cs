﻿using backend.Dtos.AdminDtos;
using backend.Dtos.AdminDtos.VetDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.VetRepo
{
    public interface IVetRepo
    {
        IEnumerable<VetDto> GetVeterinaires();
        VetDto GetVeterinaireById(Guid id);
        VetDto GetVeterinaireByUsername(string username);

        string UpdateVeterinaire(Guid UserId, UpdateVetDto updatedVet);
        string DeleteVeterinaire(Guid id);
        string AddVeterinaire(Veterinaire veterinaire);

        void SaveChanges();
    }
}
