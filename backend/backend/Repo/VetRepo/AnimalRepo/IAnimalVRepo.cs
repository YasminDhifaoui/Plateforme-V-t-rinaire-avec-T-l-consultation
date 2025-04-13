using backend.Dtos.VetDtos.AnimalDtos;
using backend.Models;

namespace backend.Repo.VetRepo.AnimalRepo
{
    public interface IAnimalVRepo
    {
        IEnumerable<AnimalVetDto> GetAnimalsByVetId(Guid vetId);

    }
}
