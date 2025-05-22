using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;

[Authorize]
public class WebRTCHub : Hub
{
    private static readonly ConcurrentDictionary<string, string> _userConnections = new();
    private static readonly ConcurrentDictionary<string, string> _activeCalls = new();

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        if (userId != null)
        {
            _userConnections[userId] = Context.ConnectionId;
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        if (userId != null)
        {
            _userConnections.TryRemove(userId, out _);

            // Clean up any active calls involving this user
            var ongoingCall = _activeCalls.FirstOrDefault(x => x.Key == userId || x.Value == userId);
            if (ongoingCall.Key != null)
            {
                await Clients.User(ongoingCall.Value).SendAsync("CallEnded", "The other user disconnected");
                _activeCalls.TryRemove(ongoingCall.Key, out _);
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    // Initiate a call
    public async Task InitiateCall(string targetUserId)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        if (callerId == null) return;

        if (_activeCalls.ContainsKey(callerId) || _activeCalls.ContainsKey(targetUserId))
        {
            await Clients.Caller.SendAsync("CallRejected", "One of the users is already in a call");
            return;
        }

        _activeCalls.TryAdd(callerId, targetUserId);
        await Clients.User(targetUserId).SendAsync("IncomingCall", callerId);
    }

    // Send WebRTC offer to another user (after call is accepted)
    public async Task SendOffer(string targetUserId, string offer)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        if (!_activeCalls.TryGetValue(callerId, out var currentTarget) || currentTarget != targetUserId)
        {
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active");
            return;
        }
        await Clients.User(targetUserId).SendAsync("ReceiveOffer", callerId, offer);
    }

    // Accept an incoming call
    public async Task AcceptCall(string callerUserId)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        if (!_activeCalls.TryGetValue(callerUserId, out var currentTarget) || currentTarget != calleeId)
        {
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active");
            return;
        }
        await Clients.User(callerUserId).SendAsync("CallAccepted", calleeId);
    }

    // Reject an incoming call
    public async Task RejectCall(string callerUserId, string reason)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        _activeCalls.TryRemove(callerUserId, out _);
        await Clients.User(callerUserId).SendAsync("CallRejected", reason ?? "Call rejected");
    }

    // End an ongoing call
    public async Task EndCall(string otherUserId)
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        if (userId == null) return;

        // Check if we're the caller or callee in an active call
        if (_activeCalls.TryGetValue(userId, out var target) && target == otherUserId)
        {
            _activeCalls.TryRemove(userId, out _);
        }
        else if (_activeCalls.TryGetValue(otherUserId, out var caller) && caller == userId)
        {
            _activeCalls.TryRemove(otherUserId, out _);
        }

        await Clients.User(otherUserId).SendAsync("CallEnded", "The other user ended the call");
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