using System.Net;
using System.Net.Mail;
using backend.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

public class MailService : IMailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<MailService> _logger;

    public MailService(IConfiguration configuration, ILogger<MailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public void SendHTMLTemplateMail(HTMLTemplateMailData mailData)
    {
        try
        {
            var smtpClient = new SmtpClient(_configuration["Smtp:Host"])
            {
                Port = int.Parse(_configuration["Smtp:Port"]),
                Credentials = new NetworkCredential(_configuration["Smtp:Username"], _configuration["Smtp:Password"]),
                EnableSsl = true
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress(_configuration["Smtp:FromEmail"]),
                Subject = mailData.EmailSubject,
                Body = mailData.GenerateEmailBody(mailData.EmailSubject,mailData.Variables),
                IsBodyHtml = true
            };
            mailMessage.To.Add(mailData.EmailToId);

            smtpClient.Send(mailMessage);
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error sending email: {ex.Message}", ex);
            throw;
        }
    }
    



}
