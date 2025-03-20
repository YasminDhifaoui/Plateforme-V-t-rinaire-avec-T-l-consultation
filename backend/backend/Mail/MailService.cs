using System.Net;
using System.Net.Mail;
using backend.Models;
using Microsoft.Extensions.Configuration;
using backend.Mail;

namespace backend.Mail
{
    public class MailService : IMailService
    {
        private readonly IConfiguration _configuration;

        public MailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public bool SendHTMLTemplateMail(HTMLTemplateMailData mailData)
        {
            try
            {
                
                var smtpClient = new SmtpClient(_configuration["SmtpSettings:Server"])
                {
                    Port = int.TryParse(_configuration["SmtpSettings:Port"], out int port) ? port : 587,
                    Credentials = new NetworkCredential(
                    _configuration["SmtpSettings:Username"],
                    _configuration["SmtpSettings:Password"]),
                    EnableSsl = bool.TryParse(_configuration["SmtpSettings:EnableSsl"], out bool enableSsl) ? enableSsl : true
                };

               

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(_configuration["SmtpSettings:SenderEmail"]),
                    Subject = mailData.EmailSubject,
                    Body = GenerateHtmlBody(mailData),
                    IsBodyHtml = true
                };
                mailMessage.To.Add(mailData.EmailToId);

                smtpClient.Send(mailMessage);

                Console.WriteLine("Email sent successfully.");
                return true;
            }
            catch (SmtpException smtpEx)
            {
                Console.WriteLine($"SMTP Error: {smtpEx.Message}");
                return false;
            }
            catch (Exception ex)
            {
                
                Console.WriteLine($"Error sending email: {ex.StackTrace}");
                return false;
            }
        }

        // cz l body fih barcha parametres tejmch t7othom f string lezm dictionary 

        private string GenerateHtmlBody(HTMLTemplateMailData mailData)
        {
            string templatePath = Path.Combine(Directory.GetCurrentDirectory(), "Templates", mailData.TemplateName);

            if (!File.Exists(templatePath))
            {
                throw new FileNotFoundException("Email template file not found.", templatePath);
            }

            string template = File.ReadAllText(templatePath);

            foreach (var variable in mailData.Variables)
            {
                template = template.Replace($"{{{variable.Key}}}", variable.Value);
            }

            return template;
        }

    }
}
