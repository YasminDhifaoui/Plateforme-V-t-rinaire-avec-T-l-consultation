namespace backend.Dtos.AdminDtos.AnimalDtos
{
    public class AddAnimalAdminDto
    {
        public string Name { get; set; } = string.Empty;
        public string Espece { get; set; } = string.Empty;
        public string Race { get; set; } = string.Empty;
        public int Age { get; set; }
        public string Sexe { get; set; } = string.Empty;
        public string Allergies { get; set; } = string.Empty;
        public string AntecedentsMedicaux { get; set; } = string.Empty; 

        public Guid OwnerId { get; set; }
    }
}
