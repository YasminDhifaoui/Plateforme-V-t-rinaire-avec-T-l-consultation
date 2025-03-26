using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.UsersDto;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Mvc;
using System;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminUsersController : ControllerBase
    {
        private readonly IAdminRepo _userRepo;

        public AdminUsersController(IAdminRepo userRepo)
        {
            _userRepo = userRepo;
        }

        // UsersList
        [HttpGet("usersList")]
        public IActionResult GetAllUsers()
        {
            var users = _userRepo.GetAllUsers();
            return Ok(users);
        }
        // GetUserByRole
        [HttpGet("GetUserByRole/{role}")]
        public IActionResult GetUserByRole(string role)
        {
            var users = _userRepo.GetUsersByRole(role);
            if (users == null) return BadRequest(new { message = "role not found" });
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
        public IActionResult UpdateUser(Guid id, [FromBody] UserUpdateDto updatedUser)
        {
            var user = _userRepo.GetUserById(id);

            if (user == null) return NotFound();

            _userRepo.UpdateUser(user.Id, updatedUser);

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
