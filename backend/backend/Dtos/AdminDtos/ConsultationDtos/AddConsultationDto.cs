namespace backend.Dtos.AdminDtos.ConsultationDtos
{
    public class AddConsultationDto
    {
        public DateTime Date { get; set; }
        public string Diagnostic { get; set; }
        public string Treatment { get; set; }
        public string Prescription { get; set; }
        public string Notes { get; set; }
        public string DocumentPath { get; set; }
        public Guid RendezVousID { get; set; }
    }
}
