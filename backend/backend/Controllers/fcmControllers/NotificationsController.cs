using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;
using backend.Services; // Your services namespace

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")] // Route: /api/Notifications
    public class NotificationsController : ControllerBase
    {
        // DTO for incoming request to send a notification
        public class NotificationRequest
        {
            public string RecipientId { get; set; } = string.Empty;
             public string RecipientAppType { get; set; } = string.Empty; // <<< NEW PROPERTY HERE

            public string SenderId { get; set; } = string.Empty; // Actual ID of the sender
            public string SenderName { get; set; } = string.Empty;
            public string MessageContent { get; set; } = string.Empty;
            public string? FileUrl { get; set; }
            public string? FileName { get; set; }
            public string? FileType { get; set; }
            public string? CallerId { get; set; }
            public string? CallerName { get; set; }
        }

        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        /// <summary>
        /// Endpoint to send a chat message notification.
        /// Call with POST to `YOUR_BACKEND_BASE_URL/api/notifications/sendChatMessage`.
        /// </summary>
        [HttpPost("sendChatMessage")]
        public async Task<IActionResult> SendChatMessage([FromBody] NotificationRequest request)
        {
            if (string.IsNullOrEmpty(request.RecipientId) || string.IsNullOrEmpty(request.SenderId) || string.IsNullOrEmpty(request.SenderName) || string.IsNullOrEmpty(request.MessageContent) || string.IsNullOrEmpty(request.RecipientAppType)) 
            {
                return BadRequest(new { message = "RecipientId, SenderId, SenderName, and MessageContent are required." });
            }

            try
            {
                await _notificationService.SendChatMessageNotificationAsync(
                    request.RecipientId,
                    request.RecipientAppType,
                    request.SenderId,
                    request.SenderName,
                    request.MessageContent,
                    request.FileUrl,
                    request.FileName,
                    request.FileType
                );
                return Ok(new { message = "Chat message notification sent (attempted)." });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[NotificationsController Error] Failed to send chat message: {ex.Message}");
                return StatusCode(500, new { message = "Internal server error while sending notification." });
            }
        }

        /// <summary>
        /// Endpoint to send an incoming call notification.
        /// Call with POST to `YOUR_BACKEND_BASE_URL/api/notifications/sendIncomingCall`.
        /// </summary>
        [HttpPost("sendIncomingCall")]
        public async Task<IActionResult> SendIncomingCall([FromBody] NotificationRequest request)
        {
            if (string.IsNullOrEmpty(request.RecipientId) || string.IsNullOrEmpty(request.CallerId) || string.IsNullOrEmpty(request.CallerName))
            {
                return BadRequest(new { message = "RecipientId, CallerId, and CallerName are required for incoming calls." });
            }

            try
            {
                await _notificationService.SendIncomingCallNotificationAsync(
                    request.RecipientId,
                    request.CallerId,
                    request.CallerName
                );
                return Ok(new { message = "Incoming call notification sent (attempted)." });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[NotificationsController Error] Failed to send incoming call: {ex.Message}");
                return StatusCode(500, new { message = "Internal server error while sending notification." });
            }
        }
    }
}