namespace backend.Dtos.VetDtos.AnimalDtos
{
    public class AnimalVetDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Espece { get; set; } = string.Empty;
        public string Race { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Sexe { get; set; } = string.Empty;
        public string Allergies { get; set; } = string.Empty;
        public string Anttecedentsmedicaux { get; set; } = string.Empty;
        public Guid OwnerId { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
