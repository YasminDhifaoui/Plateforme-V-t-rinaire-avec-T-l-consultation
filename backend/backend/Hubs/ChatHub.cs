using Microsoft.AspNetCore.SignalR;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc; // Required for HubException
using Microsoft.Extensions.Logging; // NEW: For logging

[Authorize]
public class ChatHub : Hub
{
    private readonly AppDbContext _context;
    private readonly ILogger<ChatHub> _logger; // NEW: Inject logger

    // Modified constructor to inject ILogger
    public ChatHub(AppDbContext context, ILogger<ChatHub> logger)
    {
        _context = context;
        _logger = logger; // Assign logger
    }

    public override async Task OnConnectedAsync()
    {
        var userIdString = Context.User?.FindFirst("Id")?.Value;
        _logger.LogInformation($"SignalR connected. ConnectionId: {Context.ConnectionId}, User ID from claim: {userIdString}");

        if (!string.IsNullOrEmpty(userIdString) && Guid.TryParse(userIdString, out var userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, userId.ToString());
            _logger.LogInformation($"User {userId} added to group.");
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation($"Disconnected: {exception?.Message}. ConnectionId: {Context.ConnectionId}");

        var userIdString = Context.User?.FindFirst("Id")?.Value;
        if (!string.IsNullOrEmpty(userIdString) && Guid.TryParse(userIdString, out var userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, userId.ToString());
            _logger.LogInformation($"User {userId} removed from group.");
        }
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SendMessage(Guid receiverId, string? message, string? fileUrl = null, string? fileName = null, string? fileType = null)
    {
        _logger.LogInformation("SendMessage called from ConnectionId: {ConnectionId}", Context.ConnectionId);
        var userIdString = Context.User?.FindFirst("Id")?.Value;
        _logger.LogInformation($"User ID from context: {userIdString}");
        _logger.LogInformation($"Received message: '{message}', FileUrl: '{fileUrl}', FileName: '{fileName}', FileType: '{fileType}'");


        if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var senderId))
        {
            _logger.LogWarning("SendMessage: User not authenticated or invalid sender ID.");
            throw new HubException("User not authenticated or invalid user ID");
        }

        var receiverExists = await _context.Users.AnyAsync(u => u.Id == receiverId);
        if (!receiverExists)
        {
            _logger.LogWarning("SendMessage: Receiver not found for ID: {ReceiverId}", receiverId);
            throw new HubException("Receiver not found");
        }

        if (string.IsNullOrEmpty(message) && string.IsNullOrEmpty(fileUrl))
        {
            _logger.LogWarning("SendMessage: Message or file must be provided.");
            throw new HubException("Message or file must be provided.");
        }

        var chatMessage = new ChatMessage
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = receiverId,
            Message = message,
            FileUrl = fileUrl,
            FileName = fileName,
            FileType = fileType,
            SentDate = DateTime.UtcNow
        };

        try
        {
            await _context.ChatMessages.AddAsync(chatMessage);
            await _context.SaveChangesAsync();
            _logger.LogInformation("ChatMessage saved to database successfully. MessageId: {MessageId}", chatMessage.Id);
        }
        catch (DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "Database update error when saving ChatMessage. Check schema and data types.");
            // Log inner exceptions for more detail
            if (dbEx.InnerException != null)
            {
                _logger.LogError(dbEx.InnerException, "Inner exception details for DbUpdateException.");
            }
            throw new HubException("Failed to save message due to database error.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unexpected error occurred while saving ChatMessage.");
            throw new HubException("An unexpected error occurred while saving message.");
        }

        var sender = await _context.Users.FirstOrDefaultAsync(u => u.Id == senderId);
        if (sender == null)
        {
            _logger.LogError("SendMessage: Sender not found after saving message. SenderId: {SenderId}", senderId);
            throw new HubException("Sender not found");
        }

        var messageToSend = new
        {
            SenderId = senderId,
            SenderUsername = sender.UserName,
            Message = message,
            FileUrl = fileUrl,
            FileName = fileName,
            FileType = fileType,
            SentAt = chatMessage.SentDate // Use SentDate consistent with DB model
        };

        await Clients.Group(receiverId.ToString()).SendAsync("ReceiveMessage", messageToSend);
        _logger.LogInformation("Message sent to receiver group {ReceiverId}.", receiverId);

        // Only send to sender group if they are not the receiver to avoid duplication
        if (senderId != receiverId)
        {
            await Clients.Group(senderId.ToString()).SendAsync("ReceiveMessage", messageToSend);
            _logger.LogInformation("Message sent to sender group {SenderId}.", senderId);
        }
    }
}
