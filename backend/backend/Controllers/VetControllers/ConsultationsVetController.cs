using backend.Data;
using backend.Dtos.VetDtos.ConsultationDtos;
using backend.Repo.VetRepo.ConsultationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.VetControllers
{
    [Route("api/vet/[controller]")]
    [ApiController]
    [Authorize(Policy = "Veterinaire")]
    public class ConsultationsVetController : ControllerBase
    {
        private readonly IConsultationVetRepo _repo;

        public ConsultationsVetController(IConsultationVetRepo repo)
        {
            _repo = repo;
        }

        [HttpGet("get-consultations")]
        public async Task<IActionResult> GetMyConsultations()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;
            if (!Guid.TryParse(userIdClaim, out var vetId))
                return Unauthorized("Invalid or missing vet ID claim.");

            var consultations = await _repo.GetConsultations(vetId);
            return Ok(consultations);
        }

        [HttpPost("create-consultation")]
        public async Task<IActionResult> AddConsultation([FromForm] AddConsultationVetDto dto)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;
            if (!Guid.TryParse(userIdClaim, out var vetId))
                return Unauthorized("Invalid vet ID");

            var result = await _repo.AddConsultation(dto, vetId);
            return Ok(result);
        }

        [HttpPut("update-consultation/{id}")]
        public async Task<IActionResult> UpdateConsultation(Guid id, [FromForm] UpdateConsultationVetDto dto)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;
            if (!Guid.TryParse(userIdClaim, out var vetId))
                return Unauthorized("Invalid vet ID");

            var success = await _repo.UpdateConsultation(id, dto, vetId);
            if (!success)
                return NotFound("Consultation not found or not yours.");

            return Ok("Consultation updated successfully.");
        }

        [HttpDelete("delete-consultation/{id}")]
        public async Task<IActionResult> DeleteConsultation(Guid id)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;
            if (!Guid.TryParse(userIdClaim, out var vetId))
                return Unauthorized("Invalid vet ID");

            var success = await _repo.DeleteConsultation(id, vetId);
            if (!success)
                return NotFound("Consultation not found or already deleted.");

            return Ok("Consultation deleted successfully.");
        }
    }
}
