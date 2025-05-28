using backend.Data;
using backend.Dtos.ClientDtos.ClientAuthDtos;
using backend.Dtos.ClientDtos.ProfileDtos;
using backend.Models;
using backend.Repo.ClientRepo.ProfileRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/profile")]
    [ApiController]
    [Authorize(Roles = "Client")]
    public class ClientProfileController : ControllerBase
    {
        private readonly IClientProfileRepo _profileService;

        private readonly UserManager<AppUser> _userManager;
        private readonly AppDbContext _context;

        private readonly ILogger<ClientProfileController> _logger;
        public ClientProfileController(IClientProfileRepo profileService,
              ILogger<ClientProfileController> logger,
                    UserManager<AppUser> userManager,
                                AppDbContext context)
        {
            _profileService = profileService;
            _userManager = userManager;
            _context = context;

            _logger = logger;
        }

       
        [HttpGet]
        [Route("see-profile")]

        public async Task<IActionResult> GetProfile()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var profile = await _profileService.GetProfileAsync(clientId);
            return Ok(profile);
        }

        [HttpPut]
        [Route("update-profile")]

        public async Task<IActionResult> UpdateProfile([FromBody] UpdateClientProfileDto dto)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var success = await _profileService.UpdateProfileAsync(clientId, dto);
            if (!success)
                return BadRequest("Failed to update profile");
            return Ok("profile Updated");
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ClientChangePasswordDto model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new ApiResponse
                {
                    Status = "Error",
                    Message = "Invalid input.",
                });
            }


            var userIdString = User.FindFirst("Id")?.Value;

            if (string.IsNullOrEmpty(userIdString))
            {
                _logger.LogError("User ID claim not found in token for change password request.");
                return Unauthorized(new ApiResponse { Status = "Error", Message = "User not authenticated or ID claim missing." });
            }

            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                _logger.LogError($"Invalid User ID format in token: {userIdString}");
                return Unauthorized(new ApiResponse { Status = "Error", Message = "Invalid user ID format." });
            }

            var user = await _userManager.FindByIdAsync(userId.ToString()); // UserManager.FindByIdAsync expects string ID
            if (user == null)
            {
                _logger.LogWarning($"Authenticated user with ID {userId} not found in database for change password.");
                return NotFound(new ApiResponse { Status = "Error", Message = "User not found." });
            }


            var client = _context.clients.FirstOrDefault(x => x.AppUserId == user.Id);
            if (client == null)
            {
                _logger.LogError($"client profile not found for AppUserId: {user.Id} during change password.");
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse { Status = "Error", Message = "client profile not found. Please contact support." });
            }


            var isPasswordValid = await _userManager.CheckPasswordAsync(user, model.CurrentPassword);
            if (!isPasswordValid)
            {
                _logger.LogWarning($"Failed change password attempt for user {user.Email}: Incorrect current password.");
                return BadRequest(new ApiResponse { Status = "Error", Message = "Incorrect current password." });
            }

            var result = await _userManager.ChangePasswordAsync(user, model.CurrentPassword, model.NewPassword);

            if (result.Succeeded)
            {
                _logger.LogInformation($"Password successfully changed for user: {user.Email}");
                return Ok(new ApiResponse { Status = "Success", Message = "Password changed successfully!" });
            }
            else
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                _logger.LogError($"Failed to change password for user {user.Email}: {errors}");
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = $"Failed to change password: {errors}"
                });
            }
        }
    }
}
