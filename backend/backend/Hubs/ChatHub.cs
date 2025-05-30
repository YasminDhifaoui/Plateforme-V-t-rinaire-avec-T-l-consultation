using Microsoft.AspNetCore.SignalR;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc; // Required for HubException

[Authorize]
public class ChatHub : Hub
{
    private readonly AppDbContext _context;

    public ChatHub(AppDbContext context)
    {
        _context = context;
    }

    public override async Task OnConnectedAsync()
    {
        var userIdString = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"SignalR connected. User ID from claim: {userIdString}");

        if (!string.IsNullOrEmpty(userIdString) && Guid.TryParse(userIdString, out var userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, userId.ToString());
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        Console.WriteLine($"Disconnected: {exception?.Message}");

        var userIdString = Context.User?.FindFirst("Id")?.Value;
        if (!string.IsNullOrEmpty(userIdString) && Guid.TryParse(userIdString, out var userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, userId.ToString());
        }
        await base.OnDisconnectedAsync(exception);
    }

    // Modified SendMessage to accept optional file parameters
    public async Task SendMessage(Guid receiverId, string? message, string? fileUrl = null, string? fileName = null, string? fileType = null)
    {
        Console.WriteLine("SendMessage called");

        var userIdString = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"User ID from context: {userIdString}");

        if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var senderId))
        {
            throw new HubException("User not authenticated or invalid user ID");
        }

        var receiverExists = await _context.Users.AnyAsync(u => u.Id == receiverId);
        if (!receiverExists)
        {
            throw new HubException("Receiver not found");
        }

        // Validate that either a text message or file data is provided
        if (string.IsNullOrEmpty(message) && string.IsNullOrEmpty(fileUrl))
        {
            throw new HubException("Message or file must be provided.");
        }

        var chatMessage = new ChatMessage
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = receiverId,
            Message = message, // This will be null if only a file is sent
            FileUrl = fileUrl,
            FileName = fileName,
            FileType = fileType,
            SentDate = DateTime.UtcNow
        };

        await _context.ChatMessages.AddAsync(chatMessage);
        await _context.SaveChangesAsync();

        var sender = await _context.Users.FirstOrDefaultAsync(u => u.Id == senderId);
        if (sender == null)
        {
            throw new HubException("Sender not found");
        }

        // Construct the message object to send to clients, including file details
        var messageToSend = new
        {
            SenderId = senderId,
            SenderUsername = sender.UserName,
            Message = message,
            FileUrl = fileUrl,
            FileName = fileName,
            FileType = fileType,
            SentAt = chatMessage.SentDate
        };

        // Send the message to both sender and receiver groups
        await Clients.Group(receiverId.ToString()).SendAsync("ReceiveMessage", messageToSend);
        await Clients.Group(senderId.ToString()).SendAsync("ReceiveMessage", messageToSend);
    }
}