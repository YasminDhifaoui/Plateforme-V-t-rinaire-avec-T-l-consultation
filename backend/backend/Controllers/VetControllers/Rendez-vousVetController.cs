using backend.Data;
using backend.Models;
using backend.Repo.VetRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        public IActionResult GetRendezVousList()
        {
            var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

            if (vetId == Guid.Empty)
                return Unauthorized("Veterinarian ID not found in token");

            var rendezVous = _repo.GetRendezVousByVetId(vetId);
            if (rendezVous == null || !rendezVous.Any())
                return NotFound("No rendez-vous found for this vet.");

            return Ok(rendezVous);
        }

        [HttpPut]
        [Route("update-status/{rendezVousId}")]
        public IActionResult UpdateRendezVousStatus(Guid rendezVousId, [FromBody] RendezVousStatus newStatus)
        {
            var vetId = Guid.Parse(User.FindFirst("Id")?.Value);
            if (vetId == Guid.Empty)
                return Unauthorized("Veterinarian ID not found in token");

            var rendezVous = _context.RendezVous.FirstOrDefault(r => r.Id == rendezVousId && r.VeterinaireId == vetId);
            if (rendezVous == null)
                return NotFound("Rendez-vous not found for this veterinarian.");

            rendezVous.Status = newStatus;
            rendezVous.UpdatedAt = DateTime.UtcNow;

            _context.RendezVous.Update(rendezVous);
            _context.SaveChanges();

            return Ok(new { message = "Rendez-vous status updated successfully.", rendezVous });
        }

      
    }
}
