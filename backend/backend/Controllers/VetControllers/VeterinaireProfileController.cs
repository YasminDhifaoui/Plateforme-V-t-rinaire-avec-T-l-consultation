using backend.Dtos.VetDtos.ProfileDtos;
using backend.Repo.VetRepo.ProfileRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers.VetControllers
{
    [Authorize(Roles = "Veterinaire")]
    [ApiController]
    [Route("api/veterinaire/profile")]
    public class VeterinaireProfileController : ControllerBase
    {
        private readonly IVeterinaireProfileRepo _profileService;

        public VeterinaireProfileController(IVeterinaireProfileRepo profileService)
        {
            _profileService = profileService;
        }

        [HttpGet]
        [Route("see-profile")]

        public async Task<ActionResult<VeterinaireProfileDto>> GetProfile()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var vetId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var profile = await _profileService.GetProfileAsync(vetId);
            if (profile == null) return NotFound();

            return Ok(profile);
        }

        [HttpPut]
        [Route("update-profile")]

        public async Task<IActionResult> UpdateProfile([FromBody] UpdateVeterinaireProfileDto dto)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var vetId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }
            var success = await _profileService.UpdateProfileAsync(vetId, dto);
            if (!success) return BadRequest("Failed to update profile");

            return Ok("profile updated successfully");
        }
    }

}
