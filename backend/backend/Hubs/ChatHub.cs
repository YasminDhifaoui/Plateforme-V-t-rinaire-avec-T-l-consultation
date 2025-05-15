using Microsoft.AspNetCore.SignalR;
using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/test")]
public class TestController : ControllerBase
{
    [HttpGet("log")]
    public IActionResult TestLog()
    {
        Console.WriteLine("TEST CONSOLE OUTPUT");
        return Ok("Check server console");
    }
}
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

    public async Task SendMessage(Guid receiverId, string message)
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

        var chatMessage = new ChatMessage
        {
            Id = Guid.NewGuid(),
            SenderId = senderId,
            ReceiverId = receiverId,
            Message = message,
            SentDate = DateTime.UtcNow
        };

        await _context.ChatMessages.AddAsync(chatMessage);
        await _context.SaveChangesAsync();

        var sender = await _context.Users.FirstOrDefaultAsync(u => u.Id == senderId);
        if (sender == null)
        {
            throw new HubException("Sender not found");
        }

        var messageToSend = new
        {
            SenderId = senderId,
            SenderUsername = sender.UserName,
            Message = message,
            SentAt = chatMessage.SentDate
        };

        await Clients.Group(receiverId.ToString()).SendAsync("ReceiveMessage", messageToSend);
        await Clients.Group(senderId.ToString()).SendAsync("ReceiveMessage", messageToSend);
    }

}