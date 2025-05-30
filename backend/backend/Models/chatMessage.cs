using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using backend.Models; // Assuming AppUser is in backend.Models

public class ChatMessage
{
    [Key]
    public Guid Id { get; set; }

    public Guid SenderId { get; set; }
    public Guid ReceiverId { get; set; }

    // Make Message nullable as it might be a file-only message
    public string? Message { get; set; }

    public DateTime SentDate { get; set; }

    // New fields for file attachments
    public string? FileUrl { get; set; } // URL to the stored file (e.g., /uploads/image.png)
    public string? FileName { get; set; } // Original filename (e.g., my_picture.png)
    public string? FileType { get; set; } // e.g., "image", "pdf", "document"

    [ForeignKey("SenderId")]
    public AppUser Sender { get; set; }

    [ForeignKey("ReceiverId")]
    public AppUser Receiver { get; set; }
}