using backend.Data;
using backend.Models;
using backend.Dtos;
using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IUserRepo _userRepo;

        public UserController(IUserRepo userRepo)
        {
            _userRepo = userRepo;
        }

        // UsersList
        [HttpGet("usersList")]
        public IActionResult GetUsers()
        {
            var users = _userRepo.GetUsers();
            return Ok(users);
        }

        // GetUserByID
        [HttpGet("GetUserById/{id}")]
        public IActionResult GetUserById(int id) 
        {
            var user = _userRepo.GetUserById(id);
            if (user == null) return BadRequest(new { message = "User not founds" });
            return Ok(user);
        }

        //GetUserByUsername
        [HttpGet("GetUserByUsername/{username}")]
        public IActionResult GetUserByUsername(string username)
        {
            var user=_userRepo.GetUserByUsername(username);
            if (user == null) return BadRequest(new { message = "User not found " });
            return Ok(user);
        }

        // register
        [HttpPost("register")]
        public IActionResult Register([FromBody] UserRegisterDto userReg)
        {
            if (_userRepo.GetUserByUsername(userReg.Username) != null)
                return BadRequest(new { message = "Username already exists" });

            var user = new User
            {
                Username = userReg.Username,
                Email = userReg.Email,
                Password = BCrypt.Net.BCrypt.HashPassword(userReg.Password) ,
                Role = userReg.Role
            };

            _userRepo.Register(user);

            return CreatedAtAction(nameof(GetUsers), new { id = user.Id }, new UserDto
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                Password = user.Password
            });
        }

        //Login
        [HttpPost("login")]
        public IActionResult Login([FromBody] UserLoginDto userLogin)
        {
            var existingUser = _userRepo.GetUserByUsername(userLogin.Username);
            if (existingUser == null || !BCrypt.Net.BCrypt.Verify(userLogin.Password, existingUser.Password))
                return Unauthorized(new { message = "Invalid username or password!" });

            return Ok(new { message = "Login successful!", userId = existingUser.Id });
        }

        // ResetPassword
        [HttpPut("resetPass/{id}")]
        public IActionResult ResetPassword(int id, [FromBody] ChangePasswordDto changePassword)
        {
            var user = _userRepo.GetUserById(id);
            if (user == null) return NotFound();

            _userRepo.ResetPassword(id,changePassword.NewPassword);

            return Ok(new { message = "Password updated " });
        }

        // updateUser
        [HttpPut("updateUser/{id}")]
        public IActionResult UpdateUser(int id, [FromBody] UserDto updatedUser)
        {
            var user = _userRepo.GetUserById(id);

           
            if (user == null) return NotFound();

            _userRepo.UpdateUser(user, updatedUser);

            return Ok(new { message = "user updated " });
        }

        // DeleteUser
        [HttpDelete("deleteUser/{id}")]
        public IActionResult DeleteUser(int id)
        {
            var user = _userRepo.GetUserById(id);
            if (user == null) return NotFound();

            _userRepo.DeleteUser(id);
            return Ok(new { message = "user deleted " });
        }

       
    }
}
