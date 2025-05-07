using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Twilio.Jwt.AccessToken;

namespace backend.Controllers.twilio
{
    [ApiController]
    [Route("[controller]")]
    public class VideoTokenController : ControllerBase
    {
        private readonly TwilioSettings _twilioSettings;

        public VideoTokenController(IOptions<TwilioSettings> twilioOptions)
        {
            _twilioSettings = twilioOptions.Value;
        }

        [Authorize(Roles = "Client,Veterinaire")]
        [HttpGet("video/token")]
        public IActionResult GetVideoToken(string userId, string roomName)
        {
            var token = GenerateTwilioToken(userId, roomName);
            return Ok(new { token });
        }

        private string GenerateTwilioToken(string identity, string roomName)
        {
            var videoGrant = new VideoGrant { Room = roomName };
            var grants = new HashSet<IGrant> { videoGrant };

            var token = new Token(
                _twilioSettings.AccountSid,
                _twilioSettings.ApiKeySid,
                _twilioSettings.ApiKeySecret,
                identity: identity,
                grants: grants
            );

            return token.ToJwt();
        }
    }
}
