﻿namespace backend.Mail
{
    public class MailDataModel
    {
        public string TemplateName;
        public string EmailSubject { get; set; }

        public string EmailToName { get; set; }
        public string EmailToId { get; set; }
        public Dictionary<string, string> Variables { get; set; }

        public MailDataModel() { }

       
    }
}
