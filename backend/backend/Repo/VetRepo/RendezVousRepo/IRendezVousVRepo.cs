using backend.Models;
using Microsoft.AspNetCore.Mvc;

namespace backend.Repo.VetRepo.RendezVousRepo
{

    public interface IRendezVousVRepo
    {
        Task<IEnumerable<RendezVous>> GetRendezVousByVetId(Guid vetId);

        Task<RendezVous> GetRendezVousByAnimalIdAndVetId(Guid animalId, Guid vetId);
        Task<bool> UpdateRendezVousStatus(Guid idVet, Guid rendezVousId, RendezVousStatus newStatus);
        Task saveChanges();

    }


}