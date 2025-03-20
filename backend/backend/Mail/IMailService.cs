using backend.Mail;

public interface IMailService
{
    bool SendHTMLTemplateMail(HTMLTemplateMailData mailData);
}
