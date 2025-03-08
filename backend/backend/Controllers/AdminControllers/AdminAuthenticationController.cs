using backend.Dtos;
using backend.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminAuthenticationController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly SignInManager<User> _signInManager;

        public AdminAuthenticationController(UserManager<User> userManager, SignInManager<User> signInManager)
        {
            _userManager = userManager;
            _signInManager = signInManager;
        }

        //  Register a new user
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] UserRegisterDto userReg)
        {
            var existingUser = await _userManager.FindByNameAsync(userReg.Username);
            if (existingUser != null)
                return BadRequest(new { message = "Username already exists" });

            var user = new User
            {
                UserName = userReg.Username,
                Email = userReg.Email
            };

            var result = await _userManager.CreateAsync(user, userReg.Password);
            if (!result.Succeeded)
                return BadRequest(result.Errors);

            return Ok(new { message = "User registered successfully!" });
        }

        //  Login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] UserLoginDto userLogin)
        {
            var user = await _userManager.FindByNameAsync(userLogin.Username);
            if (user == null)
                return Unauthorized(new { message = "Invalid username or password!" });

            var result = await _signInManager.PasswordSignInAsync(user, userLogin.Password, false, false);
            if (!result.Succeeded)
                return Unauthorized(new { message = "Invalid username or password!" });

            return Ok(new { message = "Login successful!", userId = user.Id });
        }

        // Password Reset 
        [HttpPut("reset-password/{id}")]
        public async Task<IActionResult> ResetPassword(string id, [FromBody] ChangePasswordDto changePassword)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "User not found" });

        
            var result = await _userManager.ChangePasswordAsync(user, user.PasswordHash, changePassword.NewPassword);

            if (!result.Succeeded)
                return BadRequest(result.Errors);

            return Ok(new { message = "Password updated successfully!" });
        }
    }
}
