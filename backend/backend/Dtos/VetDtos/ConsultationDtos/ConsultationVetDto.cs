namespace backend.Dtos.VetDtos.ConsultationDtos
{
    public class ConsultationVetDto
    {
        public Guid Id { get; set; }
        public DateTime Date { get; set; }
        public string Diagnostic { get; set; }
        public string Treatment { get; set; }
        public string Prescription { get; set; }
        public string Notes { get; set; }
        public string DocumentPath { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid RendezVousID { get; set; }
        public string ClientName { get; set; }
        public Guid AnimalId { get; set; }
        public string AnimalName { get; set;}
    }
}
