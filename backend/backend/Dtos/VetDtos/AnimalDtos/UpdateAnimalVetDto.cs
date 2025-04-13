namespace backend.Dtos.VetDtos.AnimalDtos
{
    public class UpdateAnimalVetDto
    {
        public int Age { get; set; }
        public string Allergies { get; set; } = string.Empty;
        public string AntecedentsMedicaux { get; set; } = string.Empty ;
    }
}
