using backend.Data;
using backend.Dtos.ClientDtos.ConsultationDtos;
using backend.Repo.ClientRepo.ConsultationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]
    public class ConsultationsCController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConsultationCRepo _repo;

        public ConsultationsCController(AppDbContext context, IConsultationCRepo repo)
        {
            _context = context;
            _repo = repo;
        }

        [HttpGet("my-consultations")]
        public async Task<IActionResult> GetMyConsultations()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var consultations = await _repo.GetMyConsultation(clientId);
            return Ok(consultations);
        }
    }
}
