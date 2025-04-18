using backend.Data;
using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Repo.AdminRepo.ConsultationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[controller]")]
    [ApiController]
    [Authorize(Policy = "Admin")]
    public class ConsultationController : ControllerBase
    {
        private readonly IConsultationRepo _consultationRepo;
        private readonly AppDbContext _context;

        public ConsultationController(IConsultationRepo consultationRepo, AppDbContext context)
        {
            _consultationRepo = consultationRepo;
            _context = context;
        }

        [HttpGet]
        [Route("get-all-consultations")]
        public async Task<IActionResult> GetAllConsultations()
        {
            var consultations = await _consultationRepo.GetAllConsultations();
            return Ok(consultations);
        }

        [HttpGet]
        [Route("get-consultation-by-id/{id}")]
        public async Task<IActionResult> GetConsultationById(Guid id)
        {
            var consultation = await _consultationRepo.GetConsultationById(id);
            if (consultation == null)
                return NotFound("Consultation not found");
            return Ok(consultation);
        }

        [HttpPost]
        [Route("add-consultation")]
        public async Task<IActionResult> AddConsultation([FromForm] AddConsultationDto dto)
        {
            var rdv = await _context.RendezVous.FindAsync(dto.RendezVousID);
            if (rdv == null)
            {
                return NotFound("Rendezvous not found !");
            }
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var created = await _consultationRepo.AddConsultation(dto);
            if (created == null)
                return BadRequest("Failed to create consultation (rendez-vous not found)");

            return CreatedAtAction(nameof(GetConsultationById), new { id = created.Id }, created);
        }

        [HttpPut]
        [Route("update-consultation/{id}")]
        public async Task<IActionResult> UpdateConsultation(Guid id, [FromForm] UpdateConsultationDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _consultationRepo.UpdateAsync(id, dto);

            if (result == null || result == "Consultation not found")
                return NotFound(result);

            return Ok(result); 
        }


        [HttpDelete]
        [Route("delete-consultation/{id}")]
        public async Task<IActionResult> DeleteConsultation(Guid id)
        {
            var result =await _consultationRepo.DeleteAsync(id);
            if (result == "Consultation not found")
                return NotFound(result);

            return Ok(result);
        }
    }
}
