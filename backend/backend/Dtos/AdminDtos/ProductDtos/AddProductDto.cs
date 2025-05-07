namespace backend.Dtos.AdminDtos.ProductDtos
{
    public class AddProductDto
    {
        public string NomProduit { get; set; }
        public IFormFile ImageUrl { get; set; } 
        public string Description { get; set; }
        public decimal Price { get; set; }
        public int Available { get; set; }
    }

}
