using backend.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ChatController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("history/{user1Id}/{user2Id}")]
        public async Task<IActionResult> GetChatHistory(Guid user1Id, Guid user2Id)
        {
            var messages = await _context.ChatMessages
                .Where(m => (m.SenderId == user1Id && m.ReceiverId == user2Id) ||
                            (m.SenderId == user2Id && m.ReceiverId == user1Id))
                .OrderBy(m => m.SentDate)
                .Join(
                    _context.Users,
                    m => m.SenderId,
                    u => u.Id,
                    (m, u) => new
                    {
                        SenderId = m.SenderId,
                        SenderUsername = u.UserName,
                        ReceiverId = m.ReceiverId,
                        Message = m.Message,
                        SentAt = m.SentDate
                    }
                )
                .ToListAsync();

            return Ok(messages);
        }


    }

}
