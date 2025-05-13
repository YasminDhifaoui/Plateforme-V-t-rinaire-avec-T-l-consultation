using backend.Models;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

public class ChatMessage
{
    [Key]
    public Guid Id { get; set; }

    public Guid SenderId { get; set; }
    public Guid ReceiverId { get; set; }

    public string Message { get; set; }
    public DateTime SentDate { get; set; }

    [ForeignKey("SenderId")]
    public AppUser Sender { get; set; }

    [ForeignKey("ReceiverId")]
    public AppUser Receiver { get; set; }
}
