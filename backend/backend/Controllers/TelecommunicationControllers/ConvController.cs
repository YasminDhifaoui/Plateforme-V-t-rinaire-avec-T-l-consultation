using backend.Data;
using backend.Dtos.TelecommunicationDtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers.TelecommunicationControllers
{
    [Authorize(Policy = "ClientOrVeterinaire")]

    [ApiController]
    [Route("api/[controller]")]
    public class ConvController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ConvController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("conversations")]
        public async Task<IActionResult> GetConversations()
        {
            var userIdStr = User.FindFirst("Id")?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out Guid userId))
            {
                return Unauthorized("Invalid or missing user token.");
            }

            // Get all messages where the user is sender or receiver
            var messages = await _context.ChatMessages
                  .Where(m => m.SenderId == userId || m.ReceiverId == userId)
                  .ToListAsync();

            // Group messages by conversation partner
            var groupedConversations = messages
                .GroupBy(m => m.SenderId == userId ? m.ReceiverId : m.SenderId)
                .Select(g => new
                {
                    OtherUserId = g.Key,
                    LatestMessageDate = g.Max(m => m.SentDate)
                })
                .OrderByDescending(g => g.LatestMessageDate)
                .ToList();

            var otherUserIds = groupedConversations.Select(g => g.OtherUserId).ToList();

            // Get user info for each conversation partner
            var conversationPartners = await _context.Users
                .Where(u => otherUserIds.Contains(u.Id))
                .Select(u => new ConversationDto
                {
                    UserId = u.Id,
                    Username = u.UserName,
                    Email = u.Email
                })
                .ToListAsync();

            // Join user info with latest message date to preserve ordering
            var orderedConversations = groupedConversations
                .Join(conversationPartners,
                      g => g.OtherUserId,
                      u => u.UserId,
                      (g, u) => new ConversationDto
                      {
                          UserId = u.UserId,
                          Username = u.Username,
                          Email = u.Email,
                          // Optional: add LatestMessageDate property if your DTO supports it
                      })
                .ToList();

            return Ok(orderedConversations);
        }

    }

}
