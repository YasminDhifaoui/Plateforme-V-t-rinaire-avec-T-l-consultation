using backend.Dtos.AdminDtos.ProductDtos;
using backend.Models;

namespace backend.Repo.AdminRepo.ProductsRepo
{
    public interface IProductRepository
    {
        Task <IEnumerable<Produit>> GetAllProducts();
        //Task <Produit> GetProductById(Guid id);
        Task<string> AddProduct(Produit product);
        Task<string> Update(Guid id, UpdateProductDto updatedProduct);
        Task<string> Delete(Guid id);
    }

}
