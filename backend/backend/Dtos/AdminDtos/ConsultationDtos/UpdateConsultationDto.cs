namespace backend.Dtos.AdminDtos.ConsultationDtos
{
    public class UpdateConsultationDto
    {
        public DateTime Date { get; set; }
        public string Diagnostic { get; set; }
        public string Treatment { get; set; }
        public string Prescription { get; set; }
        public string Notes { get; set; }
        public IFormFile Document { get; set; } // ✅ Accept the actual uploaded file here
        public Guid RendezVousID { get; set; }
    }
}
