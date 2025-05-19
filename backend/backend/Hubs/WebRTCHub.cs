using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;

[Authorize]
public class WebRTCHub : Hub
{
    private static readonly ConcurrentDictionary<string, string> _userConnections = new();

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        _userConnections.TryAdd(Context.ConnectionId, userId!);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _userConnections.TryRemove(Context.ConnectionId, out _);
        await base.OnDisconnectedAsync(exception);
    }

    // Send WebRTC offer to another user
    public async Task SendOffer(string targetUserId, string offer)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        await Clients.User(targetUserId).SendAsync("ReceiveOffer", callerId, offer);
    }

    // Send WebRTC answer back to caller
    public async Task SendAnswer(string callerUserId, string answer)
    {
        await Clients.User(callerUserId).SendAsync("ReceiveAnswer", answer);
    }

    // Relay ICE candidate between peers
    public async Task SendIceCandidate(string targetUserId, string candidate)
    {
        await Clients.User(targetUserId).SendAsync("ReceiveIceCandidate", candidate);
    }
}