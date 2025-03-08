using backend.Data;
using backend.Dtos;
using Microsoft.AspNetCore.Mvc;
using System;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminUsersController : ControllerBase
    {
        private readonly IUserRepo _userRepo;

        public AdminUsersController(IUserRepo userRepo)
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
        public IActionResult GetUserById(Guid id)  
        {
            var user = _userRepo.GetUserById(id);
            if (user == null) return BadRequest(new { message = "User not found" });
            return Ok(user);
        }

        // GetUserByUsername
        [HttpGet("GetUserByUsername/{username}")]
        public IActionResult GetUserByUsername(string username)
        {
            var user = _userRepo.GetUserByUsername(username);
            if (user == null) return BadRequest(new { message = "User not found" });
            return Ok(user);
        }

        // updateUser
        [HttpPut("updateUser/{id}")]
        public IActionResult UpdateUser(Guid id, [FromBody] UserDto updatedUser)  
        {
            var user = _userRepo.GetUserById(id);

            if (user == null) return NotFound();

            _userRepo.UpdateUser(user, updatedUser);

            return Ok(new { message = "User updated" });
        }

        // DeleteUser
        [HttpDelete("deleteUser/{id}")]
        public IActionResult DeleteUser(Guid id)  
        {
            var user = _userRepo.GetUserById(id);
            if (user == null) return NotFound();

            _userRepo.DeleteUser(id);
            return Ok(new { message = "User deleted" });
        }
    }
}
