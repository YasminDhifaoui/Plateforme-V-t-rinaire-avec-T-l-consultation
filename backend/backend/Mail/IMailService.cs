namespace backend.Mail
{
    public interface IMailService
    {
        void SendHTMLTemplateMail(HTMLTemplateMailData mailData);
    }
}
