namespace backend.Dtos.ClientDtos.ConsultationDtos
{
    public class ConsultationCDto
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
        public string VeterinaireName { get; set; }
    }
}
