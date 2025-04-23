using backend.Repo.VetRepo.ClientRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.VetControllers
{
    [Route("api/veterinaire/[Controller]")]
    [Controller]
    [Authorize(Policy = "Veterinaire")]
    public class ClientVetController : ControllerBase
    {
        public readonly IClientVetRepo _repo;
        public ClientVetController(IClientVetRepo repo) {
            _repo = repo;
        }
        [HttpGet]
        [Route("get-all-clients")]
        public async Task<IActionResult> GetAllClients()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var vetId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }
            var clients = await _repo.GetClients(vetId);
            return Ok(clients);
        }
    }
}
