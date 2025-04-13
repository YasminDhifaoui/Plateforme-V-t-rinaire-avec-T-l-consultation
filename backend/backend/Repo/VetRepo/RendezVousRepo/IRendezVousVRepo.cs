using backend.Models;

namespace backend.Repo.VetRepo.RendezVousRepo
{

    public interface IRendezVousVRepo
    {
        IEnumerable<RendezVous> GetRendezVousByVetId(Guid vetId);

        RendezVous GetRendezVousByAnimalIdAndVetId(Guid animalId, Guid vetId);
    }


}