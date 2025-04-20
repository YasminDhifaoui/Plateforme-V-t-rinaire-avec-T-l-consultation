using backend.Repo.ClientRepo.VaccinationRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]

    public class VaccinationCController : Controller
    {
        private readonly IVaccinationCRepo _repository;

        public VaccinationCController(IVaccinationCRepo repository)
        {
            _repository = repository;
        }
        [HttpGet]
        [Route("get-vaccinations-per-animalId/{animalId}")]
        public async Task<IActionResult> GetClientVaccinations(Guid? animalId)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            var vaccinations = await _repository.GetClientVaccinationsAsync(clientId, animalId);
            return Ok(vaccinations);
        }

    }
}
