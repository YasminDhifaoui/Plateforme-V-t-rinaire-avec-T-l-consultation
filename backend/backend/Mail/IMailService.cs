using backend.Mail;

public interface IMailService
{
    bool SendHTMLTemplateMail(MailDataModel mailData);
}
