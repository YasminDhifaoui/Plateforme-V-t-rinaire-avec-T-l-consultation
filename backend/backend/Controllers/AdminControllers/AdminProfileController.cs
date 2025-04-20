using backend.Dtos.AdminDtos.ProfileDtos;
using backend.Dtos.VetDtos.ProfileDtos;
using backend.Repo.AdminRepo.ProfileRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{

    [Authorize(Roles = "Admin")]
    [ApiController]
    [Route("api/admin/profile")]
    public class AdminProfileController : ControllerBase
    {
        private readonly IAdminProfileRepo _profileService;

        public AdminProfileController(IAdminProfileRepo profileService)
        {
            _profileService = profileService;
        }

        [HttpGet]
        [Route("see-profile")]

        public async Task<ActionResult<AdminProfileDto>> GetProfile()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var adminId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var profile = await _profileService.GetProfileAsync(adminId);
            if (profile == null) return NotFound();

            return Ok(profile);
        }
        [HttpPut]
        [Route("update-profile")]

        public async Task<IActionResult> UpdateProfile([FromBody] UpdateAdminProfileDto dto)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var adminID))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }
            var success = await _profileService.UpdateProfileAsync(adminID, dto);
            if (!success) return BadRequest("Failed to update profile");

            return Ok("profile updated successfully");
        }

    }
}
