using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Security.Claims;


namespace backend.Hubs
{
    public class WebRTCHub : Hub
    {
    private static readonly Dictionary<string, string> UserConnections = new Dictionary<string, string>();

        // Method to send an offer to the receiver
        public async Task SendOffer(string toUserId, object offer)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveOffer", offer);
            }
        }

        // Method to send an answer to the caller
        public async Task SendAnswer(string toUserId, object answer)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveAnswer", answer);
            }
        }

        // Method to send an ICE candidate to the other user
        public async Task SendIceCandidate(string toUserId, object candidate)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("ReceiveIceCandidate", candidate);
            }
        }

        // Method to reject the call
        public async Task RejectCall(string toUserId)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("CallRejected");
            }
        }

        // Method to accept the call
        public async Task AcceptCall(string toUserId)
        {
            if (UserConnections.TryGetValue(toUserId, out var connectionId))
            {
                await Clients.Client(connectionId).SendAsync("CallAccepted");
            }
        }

        // Method to handle a new connection to the hub
        public override async Task OnConnectedAsync()
        {
            var userId = Context.GetHttpContext()?.Request.Query["userId"];
            if (!string.IsNullOrEmpty(userId))
            {
                UserConnections[userId] = Context.ConnectionId;
            }

            await base.OnConnectedAsync();
        }

        // Method to handle disconnection
        public override async Task OnDisconnectedAsync(System.Exception? exception)
        {
            var userId = Context.GetHttpContext()?.Request.Query["userId"];
            if (!string.IsNullOrEmpty(userId) && UserConnections.ContainsKey(userId))
            {
                UserConnections.Remove(userId);
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}
