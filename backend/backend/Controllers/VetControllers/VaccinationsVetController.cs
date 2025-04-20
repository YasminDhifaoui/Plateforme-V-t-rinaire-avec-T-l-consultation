using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Repo.VetRepo.VaccinationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.VetControllers
{
    [Route("api/veterinaire/[controller]")]
    [ApiController]
    [Authorize(Policy = "Veterinaire")]
    public class VaccinationsVetController : ControllerBase
    {
        private readonly IVaccinationVetRepo _repo;

        public VaccinationsVetController(IVaccinationVetRepo repo)
        {
            _repo = repo;
        }

        private Guid GetVeterinaireId()
        {
            var id = User.FindFirst("Id")?.Value;
            return Guid.TryParse(id, out var vetId) ? vetId : throw new UnauthorizedAccessException();
        }

        [HttpGet]
        [Route("get-all-vaccinations")]
        public async Task<IActionResult> GetAllVaccinations()
        {
            var vetId = GetVeterinaireId();
            var vaccs = await _repo.GetVeterinaireVaccinations(vetId);
            return Ok(vaccs);
        }
        [HttpGet]
        [Route("get-vaccinations-by-animal/{animalId}")]
        public async Task<IActionResult> GetVaccinationsByAnimalId(Guid animalId)
        {
            var vetId = GetVeterinaireId();
            var result = await _repo.GetVeterinaireVaccinationsByAnimalId(vetId, animalId);
            return Ok(result);
        }


        [HttpPost]
        [Route("add-vaccination")]
        public async Task<IActionResult> AddVaccinations([FromBody] AddVaccinationDto dto)
        {
            var vetId = GetVeterinaireId();
            var result = await _repo.AddVaccination(vetId, dto);
            return Ok(result);
        }

        [HttpPut]
        [Route("update-vaccination/{id}")]
        public async Task<IActionResult> UpdateVaccinations(Guid id, [FromBody] UpdateVaccinationDto dto)
        {
            var vetId = GetVeterinaireId();
            var result = await _repo.UpdateVaccination(vetId, id, dto);
            return Ok(result);
        }

        [HttpDelete]
        [Route("delete-vaccination/{id}")]
        public async Task<IActionResult> DeleteVaccinations(Guid id)
        {
            var vetId = GetVeterinaireId();
            var result = await _repo.DeleteVaccination(vetId, id);
            return Ok(result);
        }
    }
}
