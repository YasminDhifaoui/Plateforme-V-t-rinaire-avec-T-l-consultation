using backend.Dtos.VetDtos.ProductDtos;
using backend.Repo.VetRepo.ProductRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.VetControllers
{
    [ApiController]
    [Route("api/vet/products")]
    [Authorize(Policy ="Veterinaire")]
    public class ProductsVetController : ControllerBase
    {
        private readonly IProductVetRepo _productVetRepo;

        public ProductsVetController(IProductVetRepo productVetRepo)
        {
            _productVetRepo = productVetRepo;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProductVetDto>>> GetAll()
        {
            var products = await _productVetRepo.GetAllProducts();
            return Ok(products);
        }

    }
}
