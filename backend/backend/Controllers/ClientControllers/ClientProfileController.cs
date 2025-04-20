using backend.Dtos.ClientDtos.ProfileDtos;
using backend.Repo.ClientRepo.ProfileRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/profile")]
    [ApiController]
    [Authorize(Roles = "Client")]
    public class ClientProfileController : ControllerBase
    {
        private readonly IClientProfileRepo _profileService;

        public ClientProfileController(IClientProfileRepo profileService)
        {
            _profileService = profileService;
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
    }
}
