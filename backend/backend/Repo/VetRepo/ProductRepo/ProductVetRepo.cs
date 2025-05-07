using backend.Data;
using backend.Dtos.VetDtos.ProductDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo.ProductRepo
{
    public class ProductVetRepo : IProductVetRepo
    {
        public readonly AppDbContext _context;
        public ProductVetRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<ProductVetDto>> GetAllProducts()
        {
            var products = await _context.Produits
                .Where(p => p.Available == 1)
                .ToListAsync();

            var productDtos = products.Select(p => new ProductVetDto
            {
                NomProduit = p.NomProduit,
                Description = p.Description,
                Price = p.Price,
                ImageUrl = p.ImageUrl,
                Available = p.Available
            });

            return productDtos;
        }

    }
}
