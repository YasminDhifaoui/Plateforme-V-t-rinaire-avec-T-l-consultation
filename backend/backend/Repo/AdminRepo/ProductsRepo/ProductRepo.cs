using backend.Data;
using backend.Dtos.AdminDtos.ProductDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using System;

namespace backend.Repo.AdminRepo.ProductsRepo
{
    public class ProductRepo : IProductRepository
    {
        public readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public ProductRepo(AppDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;

        }
        public async Task<IEnumerable<Produit>> GetAllProducts()
        {
            var products = await _context.Produits.ToListAsync();
            return products;
        }
        public async Task<string> AddProduct(Produit product)
        {
            await _context.Produits.AddAsync(product);
            await _context.SaveChangesAsync();
            return "Product added successfully!";
        }

        public async Task<string> Update(Guid id, UpdateProductDto updatedProduct)

        {
            var product = await _context.Produits.FindAsync(id);
            if (product == null)
                return "Product not found.";

            product.NomProduit = updatedProduct.NomProduit;
            product.Description = updatedProduct.Description;
            product.Price = updatedProduct.Price;
            product.Available = updatedProduct.Available;
            product.UpdatedAt = DateTime.UtcNow;

            if (updatedProduct.ImageUrl != null)
            {
                var imageName = Guid.NewGuid() + Path.GetExtension(updatedProduct.ImageUrl.FileName);
                var savePath = Path.Combine(_environment.WebRootPath, "images", imageName);

                using (var stream = new FileStream(savePath, FileMode.Create))
                {
                    await updatedProduct.ImageUrl.CopyToAsync(stream);
                }

                product.ImageUrl = $"/images/{imageName}";
            }

            await _context.SaveChangesAsync();
            return "Product updated successfully.";
        }

        public async Task<string> Delete(Guid id)
        {
            var product = await _context.Produits.FindAsync(id);
            if (product == null)
                return "Product not found.";

            _context.Produits.Remove(product);
            await _context.SaveChangesAsync();

            return "Product deleted successfully.";
        }

  
    }
}
