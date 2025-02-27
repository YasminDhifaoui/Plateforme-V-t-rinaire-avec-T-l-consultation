using backend.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

        // GET: api/user
        [HttpGet("usersList")]
        public IActionResult GetUsers()
        {
            return Ok(_context.Users.ToList());
        }

        
        //add
        [HttpPost("addUser")]
        public IActionResult AddUser([FromBody]User user)
        {
            _context.Users.Add(user);
            _context.SaveChanges();
            return CreatedAtAction(nameof(GetUsers), new { id = user.Id }, user);
        }
        
        //update
        [HttpPut("updateUser{id}")]
        public IActionResult UpdateUser(int id, [FromBody] User updatedUser)
        {
            var user = _context.Users.Find(id);
            if (user == null)
            {
                return NotFound();
            }

            user.username = updatedUser.username;
            user.password = updatedUser.password;
            user.email = updatedUser.email;

            _context.SaveChanges();
            return NoContent();
        }

        //search
        [HttpGet("searchUser")]
        public IActionResult SearchUsers([FromQuery] string name)
        {
            var users = _context.Users
                                .Where(u => u.username.Contains(name))
                                .ToList();
            return Ok(users);
        }
        

        //delete
        [HttpDelete("deleteUser{id}")]
        public IActionResult DeleteUser(int id)
        {
            var user = _context.Users.Find(id);
            if (user == null)
            {
                return NotFound();
            }

            _context.Users.Remove(user);
            _context.SaveChanges();
            return NoContent(); // HTTP 204 
        }


        [HttpPost("register")]
        public IActionResult Register([FromBody] User user)
        {
            if (_context.Users.Any(u => u.username == user.username))
            {
                return BadRequest(new { message = "Username already exists" });
            }

            user.password = BCrypt.Net.BCrypt.HashPassword(user.password);

            _context.Users.Add(user);
            _context.SaveChanges();
            return CreatedAtAction(nameof(GetUsers), new { id = user.Id }, user);
        }


        [HttpPost("login")]
            public IActionResult Login([FromBody] User user)
            {
                var existingUser = _context.Users.SingleOrDefault(u => u.username == user.username);

                if (existingUser == null)
                {
                    return Unauthorized(new { message = "Invalid username or password!" });
                }

                if (!BCrypt.Net.BCrypt.Verify(user.password, existingUser.password))
                {
                    return Unauthorized(new { message = "Invalid username or password!" });
                }

                return Ok(new { message = "Hello, " + user.username + "!" });
            }

        

        //update
        [HttpPut("resetPass{id}")]
        public IActionResult changePass(int id, [FromBody] User updatedUser)
        {
            var user = _context.Users.Find(id);
            if (user == null)
            {
                return NotFound();
            }
            user.password = BCrypt.Net.BCrypt.HashPassword(updatedUser.password);
            

            _context.SaveChanges();
            return Ok(new { message = "password edited !"});
        }
    }
}
