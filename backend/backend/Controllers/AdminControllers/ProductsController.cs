using backend.Dtos.AdminDtos.ProductDtos;
using backend.Models;
using backend.Repo.AdminRepo.ProductsRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Policy = "Admin")]
    public class ProductsController : ControllerBase
    {
        private readonly IProductRepository _repository;
        private readonly IWebHostEnvironment _environment;

        public ProductsController(IProductRepository repository, IWebHostEnvironment environment)
        {
            _repository = repository;
            _environment = environment;
        }

        [HttpGet("get-all-products")]
        public async Task<IActionResult> GetAllProducts()
        {
            var prod = await _repository.GetAllProducts();
            return Ok(prod);
        }

        [HttpPost("add-product")]
        public async Task<IActionResult> AddProduct([FromForm] AddProductDto dto)
        {
            if (dto == null || dto.ImageUrl == null || dto.ImageUrl.Length == 0)
                return BadRequest("Invalid product data or image.");

            var imageFileName = Guid.NewGuid() + Path.GetExtension(dto.ImageUrl.FileName);
            var imagePath = Path.Combine("wwwroot/images", imageFileName);

            using (var stream = new FileStream(imagePath, FileMode.Create))
            {
                await dto.ImageUrl.CopyToAsync(stream);
            }

            var product = new Produit
            {
                Id = Guid.NewGuid(),
                NomProduit = dto.NomProduit,
                ImageUrl = "/images/" + imageFileName,
                Description = dto.Description,
                Price = dto.Price,
                Available = dto.Available,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _repository.AddProduct(product);
            return Ok("Product added successfully!");
        }

        [HttpPut("update-product/{id}")]
        public async Task<IActionResult> UpdateProduct(Guid id, [FromForm] UpdateProductDto dto)
        {
            var result = await _repository.Update(id, dto);
            if (result == "Product not found.")
                return NotFound(result);

            return Ok(result);
        }

        [HttpDelete("delete-product/{id}")]
        public async Task<IActionResult> DeleteProduct(Guid id)
        {
            var result = await _repository.Delete(id);
            if (result == "Product not found.")
                return NotFound(result);

            return Ok(result);
        }
    }
}
