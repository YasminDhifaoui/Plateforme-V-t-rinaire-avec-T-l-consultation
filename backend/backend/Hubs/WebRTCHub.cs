using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Text.Json;

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

            string? partnerIdInCall = null;
            string? callKeyToRemove = null;

            if (_activeCalls.TryGetValue(userId, out var targetOfThisUser) && targetOfThisUser != null)
            {
                partnerIdInCall = targetOfThisUser;
                callKeyToRemove = userId;
                Console.WriteLine($"[Hub] OnDisconnected: User {userId} (disconnected) was the caller to {partnerIdInCall}.");
            }
            else
            {
                var activeCallEntry = _activeCalls.FirstOrDefault(x => x.Value == userId);
                if (activeCallEntry.Key != null)
                {
                    callKeyToRemove = activeCallEntry.Key;
                    partnerIdInCall = activeCallEntry.Key;
                    Console.WriteLine($"[Hub] OnDisconnected: User {userId} (disconnected) was the callee from {partnerIdInCall}.");
                }
            }

            if (callKeyToRemove != null)
            {
                if (_activeCalls.TryRemove(callKeyToRemove, out _))
                {
                    Console.WriteLine($"[Hub] Disconnected user {userId} ended call with {partnerIdInCall}. Call entry ({callKeyToRemove} -> {userId}) removed.");

                    if (partnerIdInCall != null && _userConnections.TryGetValue(partnerIdInCall, out string? partnerConnectionId))
                    {
                        Console.WriteLine($"[Hub] Sent CallEnded to {partnerIdInCall} (ConnectionId: {partnerConnectionId}) due to {userId}'s disconnection.");
                        await Clients.Client(partnerConnectionId).SendAsync("CallEnded", "The other user disconnected.");
                    }
                    else
                    {
                        Console.WriteLine($"[Hub] OnDisconnected: Partner {partnerIdInCall} not found or already disconnected. No CallEnded sent.");
                    }
                }
                else
                {
                    Console.WriteLine($"[Hub] OnDisconnectedAsync: Failed to remove call entry for key {callKeyToRemove} from _activeCalls (already removed?).");
                }
            }
            else
            {
                Console.WriteLine($"[Hub] OnDisconnectedAsync: User {userId} was not found as a participant in any active call.");
            }
        }
        else
        {
            Console.WriteLine($"[Hub] Unauthenticated user disconnected: ConnectionId={Context.ConnectionId}");
        }
        await base.OnDisconnectedAsync(exception);
    }

    public async Task InitiateCall(string targetUserId)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] InitiateCall from {callerId} to {targetUserId}");

        if (callerId == null)
        {
            Console.WriteLine("[Hub] InitiateCall: Caller ID is null.");
            return;
        }

        if (callerId == targetUserId)
        {
            Console.WriteLine($"[Hub] InitiateCall: Self-calling blocked for {callerId}.");
            await Clients.Caller.SendAsync("CallRejected", "Cannot call yourself.");
            return;
        }

        if (_activeCalls.ContainsKey(callerId) || _activeCalls.Any(x => x.Value == callerId) ||
            _activeCalls.ContainsKey(targetUserId) || _activeCalls.Any(x => x.Value == targetUserId))
        {
            Console.WriteLine($"[Hub] InitiateCall: User {callerId} or {targetUserId} already in a call.");
            await Clients.Caller.SendAsync("CallRejected", "One of the users is already in a call.");
            return;
        }

        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            if (_activeCalls.TryAdd(callerId, targetUserId))
            {
                await Clients.Client(targetConnectionId).SendAsync("IncomingCall", callerId);
                Console.WriteLine($"[Hub] Sent IncomingCall to {targetUserId} (ConnectionId: {targetConnectionId})");
            }
            else
            {
                Console.WriteLine($"[Hub] InitiateCall: Failed to add call {callerId}->{targetUserId} to _activeCalls. (Concurrent add failure?)");
                await Clients.Caller.SendAsync("CallRejected", "Failed to register call on server.");
            }
        }
        else
        {
            Console.WriteLine($"[Hub] InitiateCall: Target user {targetUserId} not found or not connected.");
            await Clients.Caller.SendAsync("CallRejected", "Target user is not online or not connected.");
        }
    }

    public async Task AcceptCall(string callerUserId)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] AcceptCall from {calleeId} to {callerUserId}");

        if (calleeId == null) { Console.WriteLine("[Hub] AcceptCall: Callee ID is null."); return; }

        if (!_activeCalls.TryGetValue(callerUserId, out var currentTarget) || currentTarget != calleeId)
        {
            Console.WriteLine($"[Hub] AcceptCall: Call not active or mismatch. CallerKey={callerUserId}, ExpectedTarget={calleeId}, ActualTarget={currentTarget ?? "null"}");
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active or participant mismatch.");
            return;
        }

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            await Clients.Client(callerConnectionId).SendAsync("CallAccepted", calleeId);
            Console.WriteLine($"[Hub] Sent CallAccepted to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] AcceptCall: Caller {callerUserId} not found or disconnected. Removing call entry.");
            await Clients.Caller.SendAsync("CallRejected", "Caller is not online or disconnected.");
            _activeCalls.TryRemove(callerUserId, out _);
        }
    }

    public async Task RejectCall(string callerUserId, string reason)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] RejectCall from {calleeId} for {callerUserId}. Reason: {reason}");

        if (calleeId == null) { Console.WriteLine("[Hub] RejectCall: Callee ID is null."); return; }

        if (_activeCalls.TryRemove(callerUserId, out _))
        {
            Console.WriteLine($"[Hub] RejectCall: Active call from {callerUserId} removed.");
        }
        else
        {
            Console.WriteLine($"[Hub] RejectCall: No active call found for caller {callerUserId} to remove (already removed?).");
        }

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            await Clients.Client(callerConnectionId).SendAsync("CallRejected", reason ?? "Call rejected.");
            Console.WriteLine($"[Hub] Sent CallRejected to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] RejectCall: Caller {callerUserId} not found or disconnected. No CallRejected sent.");
        }
    }

    public async Task EndCall(string otherUserId, string reason)
    {
        var userId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] EndCall from {userId} to {otherUserId}. Reason: {reason}");

        if (userId == null) { Console.WriteLine("[Hub] EndCall: Current user ID is null."); return; }

        bool removed = false;
        string? callKeyToNotifyOther = null;
        string? otherUserToNotify = null;

        if (_activeCalls.TryGetValue(userId, out var target) && target == otherUserId)
        {
            removed = _activeCalls.TryRemove(userId, out _);
            callKeyToNotifyOther = userId; 
            otherUserToNotify = otherUserId; 
            Console.WriteLine($"[Hub] EndCall: User {userId} (caller) ended call with {otherUserId}.");
        }
        else if (_activeCalls.TryGetValue(otherUserId, out var caller) && caller == userId)
        {
            removed = _activeCalls.TryRemove(otherUserId, out _);
            callKeyToNotifyOther = otherUserId;
            otherUserToNotify = otherUserId;
            Console.WriteLine($"[Hub] EndCall: User {userId} (callee) ended call from {otherUserId}.");
        }

        if (removed && otherUserToNotify != null)
        {
            Console.WriteLine($"[Hub] EndCall: Active call entry removed from _activeCalls (caller key: {callKeyToNotifyOther}).");
            if (_userConnections.TryGetValue(otherUserToNotify, out string? otherUserConnectionId))
            {
                await Clients.Client(otherUserConnectionId).SendAsync("CallEnded", reason);
                Console.WriteLine($"[Hub] Sent CallEnded to {otherUserToNotify} (ConnectionId: {otherUserConnectionId}) with reason: {reason}");
            }
            else
            {
                Console.WriteLine($"[Hub] EndCall: Other user {otherUserToNotify} not found or disconnected. No CallEnded sent.");
            }
        }
        else
        {
            Console.WriteLine($"[Hub] EndCall: No active call found for {userId} with {otherUserId} to remove or call already ended.");
        }
    }

    public async Task SendOffer(string targetUserId, JsonElement offer)
    {
        var callerId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendOffer from {callerId} to {targetUserId}");

        if (callerId == null) { Console.WriteLine("[Hub] SendOffer: Caller ID is null."); return; }

        if (!_activeCalls.TryGetValue(callerId, out var currentTarget) || currentTarget != targetUserId)
        {
            Console.WriteLine($"[Hub] SendOffer: No active call for {callerId} to {targetUserId}. Current active call: {callerId} -> {currentTarget ?? "null"}");
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active or mismatch for offer exchange.");
            return;
        }

        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            await Clients.Client(targetConnectionId).SendAsync("ReceiveOffer", new { callerId = callerId, offer = offer });
            Console.WriteLine($"[Hub] Sent ReceiveOffer to {targetUserId} (ConnectionId: {targetConnectionId}) from {callerId}");
        }
        else
        {
            Console.WriteLine($"[Hub] SendOffer: Target user {targetUserId} not found or disconnected. Ending call for caller.");
            await Clients.Caller.SendAsync("CallEnded", "Target user disconnected during offer exchange.");
            _activeCalls.TryRemove(callerId, out _);
        }
    }

    public async Task SendAnswer(string callerUserId, JsonElement answer)
    {
        var calleeId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendAnswer from {calleeId} to {callerUserId}");

        if (calleeId == null) { Console.WriteLine("[Hub] SendAnswer: Callee ID is null."); return; }

        if (!_activeCalls.TryGetValue(callerUserId, out var currentTarget) || currentTarget != calleeId)
        {
            Console.WriteLine($"[Hub] SendAnswer: No active call for {calleeId} to {callerUserId}. Current active call: {callerUserId} -> {currentTarget ?? "null"}");
            await Clients.Caller.SendAsync("CallRejected", "Call no longer active or mismatch for answer exchange.");
            return;
        }

        if (_userConnections.TryGetValue(callerUserId, out string? callerConnectionId))
        {
            await Clients.Client(callerConnectionId).SendAsync("ReceiveAnswer", answer);
            Console.WriteLine($"[Hub] Sent ReceiveAnswer to {callerUserId} (ConnectionId: {callerConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] SendAnswer: Caller {callerUserId} not found or disconnected. Ending call for callee.");
            await Clients.Caller.SendAsync("CallEnded", "Caller disconnected before answer could be sent.");
            _activeCalls.TryRemove(callerUserId, out _);
        }
    }

    public async Task SendIceCandidate(string targetUserId, JsonElement candidate)
    {
        var senderId = Context.User?.FindFirst("Id")?.Value;
        Console.WriteLine($"[Hub] SendIceCandidate from {senderId} to {targetUserId}");

        if (senderId == null) { Console.WriteLine("[Hub] SendIceCandidate: Sender ID is null."); return; }

        bool callActive = (_activeCalls.TryGetValue(senderId, out var target) && target == targetUserId) ||
                          (_activeCalls.Any(x => x.Key == targetUserId && x.Value == senderId));

        if (!callActive)
        {
            Console.WriteLine($"[Hub] SendIceCandidate: No active call found between {senderId} and {targetUserId}. Skipping candidate relay.");
            return;
        }

        if (_userConnections.TryGetValue(targetUserId, out string? targetConnectionId))
        {
            await Clients.Client(targetConnectionId).SendAsync("ReceiveIceCandidate", candidate);
            Console.WriteLine($"[Hub] Sent ReceiveIceCandidate to {targetUserId} (ConnectionId: {targetConnectionId})");
        }
        else
        {
            Console.WriteLine($"[Hub] SendIceCandidate: Target user {targetUserId} not found or disconnected. Skipping candidate relay.");
        }
    }
}