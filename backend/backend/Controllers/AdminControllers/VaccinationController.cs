using backend.Dtos.AdminDtos.VaccinationDtos;
using backend.Repo.AdminRepo.VaccinationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [ApiController]
    [Route("api/admin/vaccinations")]
    [Authorize(Policy ="Admin")]
    public class VaccinationController : ControllerBase
    {
        private readonly IVaccinationRepo _repo;

        public VaccinationController(IVaccinationRepo repo)
        {
            _repo = repo;
        }

        [HttpGet]
        [Route("get-all-vaccinations")]
        public async Task<IActionResult> GetAllVaccinations()
        {
            var result = await _repo.GetAllVaccinations();
            return Ok(result);
        }

        [HttpGet]
        [Route("get-vaccination-by-id/{id}")]

        public async Task<IActionResult> GetVaccinationsById(Guid id)
        {
            var result = await _repo.GetVaccinationById(id);
            if (result == null)
                return NotFound("Vaccination not found");
            return Ok(result);
        }

        [HttpGet]
        [Route("get-vaccination-by-name/{name}")]

        public async Task<IActionResult> GetVaccinationsByName(string name)
        {
            var result = await _repo.GetVaccinationByName(name);
            if (result == null)
                return NotFound("Vaccination not found");
            return Ok(result);
        }

        [HttpPost]
        [Route("add-vaccination")]
        public async Task<IActionResult> AddVaccinations([FromBody] AddVaccinationDto dto)
        {
            var result = await _repo.AddVaccination(dto);
            return Ok(result);
        }

        [HttpPut]
        [Route("update-vaccination/{id}")]
        public async Task<IActionResult> UpdateVaccinations(Guid id, [FromBody] UpdateVaccinationDto dto)
        {
            var result = await _repo.UpdateVaccination(id, dto);
            return Ok(result);
        }

        [HttpDelete]
        [Route("delete-vaccination/{id}")]

        public async Task<IActionResult> DeleteVaccinations(Guid id)
        {
            var result = await _repo.DeleteVaccination(id);
            return Ok(result);
        }
    }
}
