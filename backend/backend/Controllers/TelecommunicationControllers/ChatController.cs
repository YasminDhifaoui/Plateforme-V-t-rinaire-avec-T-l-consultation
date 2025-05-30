using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization; // Add this using directive
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Models; // Assuming AppUser is in backend.Models
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Claims; // Needed for Context.User.FindFirst

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")] // Base route: /api/chat
    [Authorize] // IMPORTANT: Add this to secure the endpoint
    public class ChatController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ChatController(AppDbContext context)
        {
            _context = context;
        }

        // Endpoint to get chat history between two users
        // GET: api/chat/history/{user1Id}/{user2Id}
        [HttpGet("history/{user1Id}/{user2Id}")]
        public async Task<IActionResult> GetChatHistory(Guid user1Id, Guid user2Id)
        {
            // IMPORTANT: Add authorization check to ensure the requesting user is part of the chat
            var currentUserIdString = User.FindFirst("Id")?.Value;
            if (string.IsNullOrEmpty(currentUserIdString) || !Guid.TryParse(currentUserIdString, out var currentUserId))
            {
                return Unauthorized("User not authenticated or invalid user ID.");
            }

            if (currentUserId != user1Id && currentUserId != user2Id)
            {
                return Forbid("You are not authorized to view this chat history.");
            }

            // Fetch messages where sender is user1 and receiver is user2, OR
            // sender is user2 and receiver is user1.
            // Order by SentDate to get chronological history.
            var messages = await _context.ChatMessages
                .Where(m => (m.SenderId == user1Id && m.ReceiverId == user2Id) ||
                (m.SenderId == user2Id && m.ReceiverId == user1Id))
                .OrderBy(m => m.SentDate)
                .Join(
                    _context.Users,
                    m => m.SenderId,
                    u => u.Id,
                    (m, u) => new // Anonymous object for the response
                    {
                        m.Id,
                        m.SenderId,
                        SenderUsername = u.UserName, // Include SenderUsername
                        m.ReceiverId,
                        m.Message,
                        SentDate = m.SentDate, // Use SentDate to match Flutter model
                        m.FileUrl,    // IMPORTANT: Include new file fields
                        m.FileName,   // IMPORTANT: Include new file fields
                        m.FileType    // IMPORTANT: Include new file fields
                    }
                )
                .ToListAsync();

            if (messages == null || !messages.Any())
            {
                return Ok(new List<object>()); // Return empty list if no messages
            }

            return Ok(messages);
        }
    }
}
