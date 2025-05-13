using Microsoft.AspNetCore.SignalR;
using backend.Data;
using backend.Models;

public class ChatHub : Hub
{
    private readonly AppDbContext _context;

    public ChatHub(AppDbContext context)
    {
        _context = context;
    }

    public async Task SendMessage(Guid senderId, Guid receiverId, string message)
    {
        var chatMessage = new ChatMessage
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = receiverId,
            Message = message,
            SentDate = DateTime.UtcNow
        };

        _context.ChatMessages.Add(chatMessage);
        await _context.SaveChangesAsync();

        // Notify the receiver
        await Clients.User(receiverId.ToString()).SendAsync("ReceiveMessage", chatMessage);
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        Console.WriteLine($"User connected: {userId}");
        await base.OnConnectedAsync();
    }
}
