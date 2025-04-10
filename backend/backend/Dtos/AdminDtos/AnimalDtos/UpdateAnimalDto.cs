namespace backend.Dtos.AdminDtos.AnimalDtos
{
    public class UpdateAnimalDto
    {
        public string Name { get; set; }
        public string Espece { get; set; }
        public string Race { get; set; }
        public int Age { get; set; }
        public string Sexe { get; set; }
        public string Allergies { get; set; }
        public string AntecedentsMedicaux { get; set; }
        public Guid OwnerId { get; set; }

    }
}
