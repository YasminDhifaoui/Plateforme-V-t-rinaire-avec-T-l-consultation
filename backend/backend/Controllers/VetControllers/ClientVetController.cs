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

        [HttpGet]
        [Route("get-client/{clientId}")]
        public async Task<IActionResult> GetClientById(Guid clientId)
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var vetId))
            {
                return Unauthorized("Invalid or missing user ID claim.");
            }

            // You can optionally verify that the vet has access to this client here,
            // or just return the client info if your repo method handles that.

            var client = await _repo.GetClientById(clientId);
            if (client == null)
            {
                return NotFound($"Client with id {clientId} not found.");
            }
            return Ok(client);
        }

    }
}
