/*using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Twilio.Jwt.AccessToken;

namespace backend.Controllers.twilio
{
    public class VideoToken : ControllerBase
    {
        [Authorize(Roles = "Client,Veterinaire")]
        [HttpGet("video/token")]
        public IActionResult GetVideoToken(string userId, string roomName)
        {
            var token = GenerateTwilioToken(userId, roomName);
            return Ok(new { token });
        }
        public string GenerateTwilioToken(string identity, string roomName)
        {
            const string accountSid = "US2711e2d152f31c99894c7e635cac951d";
            const string apiKeySid = "SK2a528bab19544772b0f3776470b96ce7";
            const string apiKeySecret = "aG6isiUTZPSjuERXbnQvuWnCNTlEUpHU";

            var videoGrant = new VideoGrant { Room = roomName };
            var grants = new HashSet<IGrant> { videoGrant };

            var token = new Token(
                accountSid,
                apiKeySid,
                apiKeySecret,
                identity: identity,
                grants: grants
            );

            return token.ToJwt();
        }


    }
}
*/