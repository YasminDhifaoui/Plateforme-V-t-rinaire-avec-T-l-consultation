using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Security.Claims;


[Authorize]

public class WebRTCHub : Hub
    {
        private static readonly ConcurrentDictionary<string, string> UserConnections = new();

        public async Task SendOffer(string toUserId, object offer)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveOffer", offer);
            }
        }

        public async Task SendAnswer(string toUserId, object answer)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveAnswer", answer);
            }
        }

        public async Task SendIceCandidate(string toUserId, object candidate)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveIceCandidate", candidate);
            }
        }

        public async Task RejectCall(string toUserId)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("CallRejected");
            }
        }

        public async Task AcceptCall(string toUserId)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("CallAccepted");
            }
        }

        public override async Task OnConnectedAsync()
        {
            var userIdString = Context.User?.FindFirst("Id")?.Value;
            if (!string.IsNullOrEmpty(userIdString))
            {
                UserConnections[userIdString] = Context.ConnectionId;
                Console.WriteLine($"User {userIdString} connected with connectionId {Context.ConnectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userIdString = Context.User?.FindFirst("Id")?.Value;
            if (!string.IsNullOrEmpty(userIdString))
            {
                UserConnections.TryRemove(userIdString, out _);
                Console.WriteLine($"User {userIdString} disconnected");
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
