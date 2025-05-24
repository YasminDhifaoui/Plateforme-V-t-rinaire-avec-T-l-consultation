using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Text.Json; // For System.Text.Json
// For Newtonsoft.Json (if preferred) using Newtonsoft.Json;

[Authorize]
public class WebRTCHub : Hub
{
    // Stores userId -> connectionId mapping
    private static readonly ConcurrentDictionary<string, string> _userConnections = new();
    // Stores active calls: CallerId -> TargetId (or vice versa)
    private static readonly ConcurrentDictionary<string, string> _activeCalls = new();

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        if (userId != null)
        {
            _userConnections[userId] = Context.ConnectionId;
            Console.WriteLine($"[Hub] User connected: UserId={userId}, ConnectionId={Context.ConnectionId}");
        }
        else
        {
            Console.WriteLine($"[Hub] Unauthenticated user connected: ConnectionId={Context.ConnectionId}");
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        if (userId != null)
        {
            _userConnections.TryRemove(userId, out _);
            Console.WriteLine($"[Hub] User disconnected: UserId={userId}, ConnectionId={Context.ConnectionId}");

            // Find and clean up any active calls involving this user
            var ongoingCall = _activeCalls.FirstOrDefault(x => x.Key == userId || x.Value == userId);
            if (ongoingCall.Key != null) // If a call was found
            {
                string otherUserId = (ongoingCall.Key == userId) ? ongoingCall.Value : ongoingCall.Key;

                // Remove the call from active calls (try to remove both potential keys)
                _activeCalls.TryRemove(ongoingCall.Key, out _);
                _activeCalls.TryRemove(otherUserId, out _); // In case the key was the other user's ID

                if (_userConnections.TryGetValue(otherUserId, out string? otherUserConnectionId))
                {
                    await Clients.Client(otherUserConnectionId).SendAsync("CallEnded", "The other user disconnected.");
                    Console.WriteLine($"[Hub] Disconnected user {userId} ended call with {otherUserId}");
                }
            }
        }
        else
        {
            Console.WriteLine($"[Hub] Unauthenticated user disconnected: ConnectionId={Context.ConnectionId}");
        }
        await base.OnDisconnectedAsync(exception);
    }

    // Initiate a call
    public async Task InitiateCall(string targetUserId)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] InitiateCall from {callerId} to {targetUserId}");

        if (callerId == null)
        {
            Console.WriteLine("[Hub] InitiateCall: Caller ID is null.");
            return;
        }

        if (_activeCalls.ContainsKey(callerId) || _activeCalls.ContainsKey(targetUserId))
        {
            Console.WriteLine($"[Hub] InitiateCall: User {callerId} or {targetUserId} already in a call.");
            await Clients.Caller.SendAsync("CallRejected", "One of the users is already in a call");
            return;
        }

        // Check if target user is connected
        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            _activeCalls.TryAdd(callerId, targetUserId); // Map caller to target
            // Use Clients.Client with the looked-up connection ID
            await Clients.Client(targetConnectionId).SendAsync("IncomingCall", callerId);
            Console.WriteLine($"[Hub] Sent IncomingCall to {targetUserId} (ConnectionId: {targetConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] InitiateCall: Target user {targetUserId} not found or not connected.");
            await Clients.Caller.SendAsync("CallRejected", "Target user is not online or not connected.");
        }
    }

    // Accept an incoming call
    public async Task AcceptCall(string callerUserId)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] AcceptCall from {calleeId} to {callerUserId}");

        if (calleeId == null) { return; }

        if (!_activeCalls.TryGetValue(callerUserId, out var currentTarget) || currentTarget != calleeId)
        {
            Console.WriteLine($"[Hub] AcceptCall: Call not active or mismatch. CallerKey={callerUserId}, ExpectedTarget={calleeId}, ActualTarget={currentTarget}");
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active");
            return;
        }

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            // Use Clients.Client with the looked-up connection ID
            await Clients.Client(callerConnectionId).SendAsync("CallAccepted", calleeId);
            Console.WriteLine($"[Hub] Sent CallAccepted to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] AcceptCall: Caller {callerUserId} not found or disconnected.");
            await Clients.Caller.SendAsync("CallRejected", "Caller is not online or disconnected.");
            _activeCalls.TryRemove(callerUserId, out _); // Clean up the call if caller disconnected
        }
    }

    // Reject an incoming call
    public async Task RejectCall(string callerUserId, string reason)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] RejectCall from {calleeId} for {callerUserId}. Reason: {reason}");

        if (calleeId == null) { return; }

        _activeCalls.TryRemove(callerUserId, out _); // Remove the call from active calls

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            await Clients.Client(callerConnectionId).SendAsync("CallRejected", reason ?? "Call rejected");
            Console.WriteLine($"[Hub] Sent CallRejected to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] RejectCall: Caller {callerUserId} not found or disconnected.");
        }
    }

    // End an ongoing call
    public async Task EndCall(string otherUserId)
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] EndCall from {userId} to {otherUserId}");

        if (userId == null) { return; }

        // Determine which key in _activeCalls to remove
        bool removed = false;
        if (_activeCalls.TryGetValue(userId, out var target) && target == otherUserId)
        {
            removed = _activeCalls.TryRemove(userId, out _);
        }
        else if (_activeCalls.TryGetValue(otherUserId, out var caller) && caller == userId)
        {
            removed = _activeCalls.TryRemove(otherUserId, out _);
        }

        if (removed)
        {
            Console.WriteLine($"[Hub] EndCall: Active call between {userId} and {otherUserId} removed.");
        }
        else
        {
            Console.WriteLine($"[Hub] EndCall: No active call found for {userId} and {otherUserId}.");
        }

        if (_userConnections.TryGetValue(otherUserId, out string? otherUserConnectionId))
        {
            await Clients.Client(otherUserConnectionId).SendAsync("CallEnded", "The other user ended the call.");
            Console.WriteLine($"[Hub] Sent CallEnded to {otherUserId} (ConnectionId: {otherUserConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] EndCall: Other user {otherUserId} not found or disconnected.");
        }
    }

    // Send WebRTC offer
    // CHANGE: Receive as JsonElement (System.Text.Json) or JObject (Newtonsoft.Json)
    public async Task SendOffer(string targetUserId, JsonElement offer) // Changed type from string to JsonElement
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendOffer from {callerId} to {targetUserId}");

        if (callerId == null) { return; }

        if (!_activeCalls.TryGetValue(callerId, out var currentTarget) || currentTarget != targetUserId)
        {
            Console.WriteLine($"[Hub] SendOffer: Call no longer active. CallerKey={callerId}, ExpectedTarget={targetUserId}, ActualTarget={currentTarget}");
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active"); // Send rejection
            return;
        }

        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            // Send the JSON directly. Flutter_WebRTC expects a Map.
            await Clients.Client(targetConnectionId).SendAsync("ReceiveOffer", callerId, offer);
            Console.WriteLine($"[Hub] Sent ReceiveOffer to {targetUserId} (ConnectionId: {targetConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] SendOffer: Target user {targetUserId} not found or disconnected.");
            await Clients.Caller.SendAsync("CallRejected", "Target user disconnected during offer exchange.");
            // Consider ending the call if target user disappears
            _activeCalls.TryRemove(callerId, out _);
        }
    }

    // Send WebRTC answer
    // CHANGE: Receive as JsonElement (System.Text.Json) or JObject (Newtonsoft.Json)
    public async Task SendAnswer(string callerUserId, JsonElement answer) // Changed type from string to JsonElement
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendAnswer from {calleeId} to {callerUserId}");

        if (calleeId == null) { return; }

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            // Send the JSON directly
            await Clients.Client(callerConnectionId).SendAsync("ReceiveAnswer", answer);
            Console.WriteLine($"[Hub] Sent ReceiveAnswer to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] SendAnswer: Caller {callerUserId} not found or disconnected.");
            // Consider ending the call if caller disappears during answer exchange
            _activeCalls.TryRemove(callerUserId, out _); // Assumes caller is key
        }
    }

    // Relay ICE candidate between peers
    // CHANGE: Receive as JsonElement (System.Text.Json) or JObject (Newtonsoft.Json)
    public async Task SendIceCandidate(string targetUserId, JsonElement candidate) // Changed type from string to JsonElement
    {
        var senderId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendIceCandidate from {senderId} to {targetUserId}");

        if (senderId == null) { return; }

        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            // Send the JSON directly
            await Clients.Client(targetConnectionId).SendAsync("ReceiveIceCandidate", candidate);
            Console.WriteLine($"[Hub] Sent ReceiveIceCandidate to {targetUserId} (ConnectionId: {targetConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] SendIceCandidate: Target user {targetUserId} not found or disconnected.");
        }
    }
}