namespace backend.Dtos.VetDtos.ProductDtos
{
    public class ProductVetDto
    {
        public string NomProduit { get; set; }
        public string ImageUrl { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public int Available { get; set; }
    }
}
