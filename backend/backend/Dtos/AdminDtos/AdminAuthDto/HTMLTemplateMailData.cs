namespace backend.Dtos.AdminDtos.AdminAuthDto
{
    public class HTMLTemplateMailData
    {
        public string TemplateName { get; set; }  
        public string EmailSubject { get; set; }  
        public string EmailToName { get; set; }  
        public string EmailToId { get; set; }  
        public Dictionary<string, string> Variables { get; set; } 

        public HTMLTemplateMailData()
        {
            Variables = new Dictionary<string, string>();
        }
    }
}
