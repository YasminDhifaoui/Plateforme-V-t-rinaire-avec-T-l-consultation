using backend.Data;
using backend.Models;
using backend.Dtos; 
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Net;
using System.Net.Mail;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UserController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/user/usersList
        [HttpGet("usersList")]
        public IActionResult GetUsers()
        {
            return Ok(_context.Users.ToList());
        }

        // POST: api/user/addUser
        [HttpPost("addUser")]
        public IActionResult AddUser([FromBody] User user)
        {
            user.Password = BCrypt.Net.BCrypt.HashPassword(user.Password);
            _context.Users.Add(user);
            _context.SaveChanges();
            return CreatedAtAction(nameof(GetUsers), new { id = user.Id }, user);
        }

        // PUT: api/user/updateUser/{id}
        [HttpPut("updateUser/{id}")]
        public IActionResult UpdateUser(int id, [FromBody] User updatedUser)
        {
            var user = _context.Users.Find(id);
            if (user == null) return NotFound();

            user.Username = updatedUser.Username;
            user.Email = updatedUser.Email;
            user.UpdatedAt = DateTime.UtcNow;

            _context.SaveChanges();
            return NoContent();
        }

        // DELETE: api/user/deleteUser/{id}
        [HttpDelete("deleteUser/{id}")]
        public IActionResult DeleteUser(int id)
        {
            var user = _context.Users.Find(id);
            if (user == null) return NotFound();

            _context.Users.Remove(user);
            _context.SaveChanges();
            return NoContent();
        }

        // POST: api/user/register
        [HttpPost("register")]
        public IActionResult Register([FromBody] User user)
        {
            if (_context.Users.Any(u => u.Username == user.Username))
            {
                return BadRequest(new { message = "Username already exists" });
            }

            user.Password = BCrypt.Net.BCrypt.HashPassword(user.Password);
            user.CreatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;
            _context.Users.Add(user);
            _context.SaveChanges();

            return CreatedAtAction(nameof(GetUsers), new { id = user.Id }, user);
        }

        // POST: api/user/login
        [HttpPost("login")]
        public IActionResult Login([FromBody] User user)
        {
            var existingUser = _context.Users.SingleOrDefault(u => u.Username == user.Username);
            if (existingUser == null || !BCrypt.Net.BCrypt.Verify(user.Password, existingUser.Password))
            {
                return Unauthorized(new { message = "Invalid username or password!" });
            }

            if (existingUser.TwoFactorEnabled)
            {
                var random = new Random();
                string otpCode = random.Next(100000, 999999).ToString();

                existingUser.TwoFactorCode = otpCode;
                existingUser.TwoFactorExpiration = DateTime.UtcNow.AddMinutes(5);
                _context.SaveChanges();

                SendTwoFactorCode(existingUser.Email, otpCode);

                return Ok(new { message = "2FA code sent to your email!", userId = existingUser.Id });
            }

            return Ok(new { message = "Login successful!", userId = existingUser.Id });
        }

        // POST: api/user/verify-2fa
        [HttpPost("verify-2fa")]
        public IActionResult VerifyTwoFactor([FromBody] TwoFactorDto dto)
        {
            var user = _context.Users.Find(dto.UserId);
            if (user == null || user.TwoFactorCode != dto.Code || user.TwoFactorExpiration < DateTime.UtcNow)
            {
                return Unauthorized(new { message = "Invalid or expired 2FA code!" });
            }

            user.TwoFactorCode = null;
            user.TwoFactorExpiration = null;
            _context.SaveChanges();

            return Ok(new { message = "2FA verification successful!" });
        }

        // PUT: api/user/resetPass/{id}
        [HttpPut("resetPass/{id}")]
        public IActionResult ChangePassword(int id, [FromBody] User updatedUser)
        {
            var user = _context.Users.Find(id);
            if (user == null) return NotFound();

            user.Password = BCrypt.Net.BCrypt.HashPassword(updatedUser.Password);
            user.UpdatedAt = DateTime.UtcNow;
            _context.SaveChanges();

            return Ok(new { message = "Password updated successfully!" });
        }

        // method to send 2FA email
        private void SendTwoFactorCode(string email, string code)
        {
            var smtpClient = new SmtpClient("smtp.gmail.com")
            {
                Port = 587,
                Credentials = new NetworkCredential("yasmingargouri04@gmail.com", "password"),
                EnableSsl = true,
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress("yasmingargouri04@gmail.com"),
                Subject = "Your 2FA Code",
                Body = $"Your 2FA code is: {code}",
                IsBodyHtml = false,
            };
            mailMessage.To.Add(email);

            smtpClient.Send(mailMessage);
        }
    }
}
