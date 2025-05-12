using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;


namespace backend.Hubs
{
    public class WebRTCHub : Hub
    {
        public override Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                Context.Abort();
            }
            return base.OnConnectedAsync();
        }

        public async Task SendOffer(string toUserId, object offer)
            => await Clients.User(toUserId).SendAsync("ReceiveOffer", offer);

        public async Task SendAnswer(string toUserId, object answer)
            => await Clients.User(toUserId).SendAsync("ReceiveAnswer", answer);

        public async Task SendIceCandidate(string toUserId, object candidate)
            => await Clients.User(toUserId).SendAsync("ReceiveIceCandidate", candidate);
    }
}
