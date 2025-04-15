using backend.Dtos.AdminDtos.ConsultationDtos;
using backend.Models;
using backend.Repo.AdminRepo.ConsultationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[Controller]")]
    [Controller]
    //[Authorize(Policy = "Admin")]
    public class ConsultationController : ControllerBase
    {
        private readonly IConsultationRepo _consultationRepo;

        public ConsultationController(IConsultationRepo consultationRepo)
        {
            _consultationRepo = consultationRepo;
        }

        [HttpGet]
        [Route("/get-all-consultations")]
        public async Task<IActionResult> GetAllConsultations()
        {
            var consultations = await _consultationRepo.GetAllConsultations();
            return Ok(consultations);
        }

        [HttpGet]
        [Route("/get-consultation-by-id/{id}")]
        public async Task<IActionResult> GetConsultationById(Guid id)
        {
            var consultation = await _consultationRepo.GetConsultationById(id);
            if (consultation == null)
                return NotFound("Consultation not found");
            return Ok(consultation);
        }

        [HttpPost]
        [Route("/add-consultation")]
        public async Task<IActionResult> AddConsultation([FromBody] AddConsultationDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var created = await _consultationRepo.AddConsultation(dto);
            if (created == null)
                return BadRequest("Failed to create consultation (rendez-vous not found)");

            return CreatedAtAction(nameof(GetConsultationById), new { id = created.Id }, created);
        }

        [HttpPut]
        [Route("/update-consultation/{id}")]
        public IActionResult UpdateConsultation(Guid id, [FromBody] UpdateConsultationDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = _consultationRepo.UpdateAsync(id, dto);
            if (result == "Consultation not found")
                return NotFound(result);

            return Ok(result);
        }

        [HttpDelete]
        [Route("/delete-consultation/{id}")]
        public IActionResult DeleteConsultation(Guid id)
        {
            var result = _consultationRepo.DeleteAsync(id);
            if (result == "Consultation not found")
                return NotFound(result);

            return Ok(result);
        }
    }
}
