namespace backend.Mail
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

        public string GenerateEmailBody(string templateName, Dictionary<string, string> variables)
        {
            string emailTemplatePath = Path.Combine(Directory.GetCurrentDirectory(), "EmailTemplates", templateName + ".html");

            if (!System.IO.File.Exists(emailTemplatePath))
            {
                throw new FileNotFoundException($"Email template {templateName} not found.");
            }

            string emailBody = System.IO.File.ReadAllText(emailTemplatePath);

            foreach (var variable in variables)
            {
                emailBody = emailBody.Replace("{{" + variable.Key + "}}", variable.Value);
            }

            return emailBody;
        }
    }
}
