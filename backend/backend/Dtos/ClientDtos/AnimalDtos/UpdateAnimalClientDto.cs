namespace backend.Dtos.ClientDtos.AnimalDtos
{
    public class UpdateAnimalClientDto
    {
        public string Name { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Allergies { get; set; } = string.Empty;
        public string AntecedentsMedicaux { get; set; } = string.Empty; 

    }
}
