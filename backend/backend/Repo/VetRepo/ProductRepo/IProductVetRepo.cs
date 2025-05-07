using backend.Dtos.VetDtos.ProductDtos;
using backend.Models;

namespace backend.Repo.VetRepo.ProductRepo
{
    public interface IProductVetRepo
    {
        Task<IEnumerable<ProductVetDto>> GetAllProducts();

    }
}
