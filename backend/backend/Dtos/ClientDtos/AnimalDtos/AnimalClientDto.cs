namespace backend.Dtos.ClientDtos.AnimalDtos
{
    public class AnimalClientDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Espece { get; set; } = string.Empty;
        public string Race { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Sexe { get; set; } = string.Empty;
        public string Allergies { get; set; } = string.Empty;
        public string Anttecedentsmedicaux { get; set; } = string.Empty;    
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
