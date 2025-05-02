using backend.Data;
using backend.Models;
using backend.Repo.VetRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers.VetControllers
{
    [Route("api/veterinaire/[controller]")]
    [ApiController]
    [Authorize(Policy = "Veterinaire")] 
    public class RendezVousVetController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IRendezVousVRepo _repo;

        public RendezVousVetController(AppDbContext context, IRendezVousVRepo repo)
        {
            _context = context;
            _repo = repo;
        }

        [HttpGet]
        [Route("rendez-vous-list")]
        public async Task<IActionResult> GetRendezVousList()
        {
            var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

            if (vetId == Guid.Empty)
                return Unauthorized("Veterinarian ID not found in token");

            var rendezVous =await _repo.GetRendezVousByVetId(vetId);
            if (rendezVous == null )
                return NotFound("No rendez-vous found for this vet.");

            return Ok(rendezVous);
        }

        [HttpPut]
        [Route("update-status/{rendezVousId}")]
        public async Task<IActionResult> UpdateRendezVousStatus(Guid rendezVousId, [FromBody] RendezVousStatus newStatus)

        {
            var vetId = Guid.Parse(User.FindFirst("Id")?.Value);
            if (vetId == Guid.Empty)
                return Unauthorized("Veterinarian ID not found in token");

            var success = await _repo.UpdateRendezVousStatus(vetId, rendezVousId, newStatus);

            if (!success)
                return NotFound(new { message = "Rendez-vous not found for this veterinarian" });

            return Ok(new { message = "Rendez-vous status updated successfully." });
        }

      
    }
}
