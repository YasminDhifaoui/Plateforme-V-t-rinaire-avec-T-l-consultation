namespace backend.Mail
{
    public class MailDataModel
    {
        public string TemplateName = string.Empty;
        public string EmailSubject { get; set; } = string.Empty;

        public string EmailToName { get; set; } = string.Empty;
        public string EmailToId { get; set; } = string.Empty;
        public Dictionary<string, string> Variables { get; set; } = new Dictionary<string, string>();

        public MailDataModel() { }

       
    }
}
