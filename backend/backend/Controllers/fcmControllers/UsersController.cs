using backend.Services;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;

namespace backend.Controllers.fcmControllers
{
    [ApiController]
    [Route("api/[controller]")] // Route: /api/Users
    public class UsersController : ControllerBase
    {
        // DTO for incoming request to save FCM token
        public class SaveFcmTokenRequest
        {
            public string UserId { get; set; } = string.Empty;
            public string FcmToken { get; set; } = string.Empty;
            public string AppType { get; set; } = string.Empty; // e.g., "vet", "client"
        }

        private readonly IFcmTokenService _fcmTokenService;

        public UsersController(IFcmTokenService fcmTokenService)
        {
            _fcmTokenService = fcmTokenService;
        }

        /// <summary>
        /// Endpoint to save or update a user's FCM token.
        /// Your Flutter app will call this with POST to `YOUR_BACKEND_BASE_URL/api/users/savefcmtoken`.
        /// </summary>
        [HttpPost("savefcmtoken")]
        public async Task<IActionResult> SaveFcmToken([FromBody] SaveFcmTokenRequest request)
        {
            if (string.IsNullOrEmpty(request.UserId) || string.IsNullOrEmpty(request.FcmToken) || string.IsNullOrEmpty(request.AppType))
            {
                return BadRequest(new { message = "UserId, FcmToken, and AppType are required." });
            }

            try
            {
                await _fcmTokenService.SaveTokenAsync(request.UserId, request.FcmToken, request.AppType);
                return Ok(new { message = "FCM token saved successfully." });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[UsersController Error] Failed to save FCM token: {ex.Message}");
                return StatusCode(500, new { message = "Internal server error while saving token." });
            }
        }
    }
}