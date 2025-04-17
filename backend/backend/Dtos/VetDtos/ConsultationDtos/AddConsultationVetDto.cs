namespace backend.Dtos.VetDtos.ConsultationDtos
{
    public class AddConsultationVetDto
    {
        public DateTime Date { get; set; }
        public string Diagnostic { get; set; }
        public string Treatment { get; set; }
        public string Prescription { get; set; }
        public string Notes { get; set; }
        public IFormFile Document { get; set; }
        public Guid RendezVousID { get; set; }
    }
}
