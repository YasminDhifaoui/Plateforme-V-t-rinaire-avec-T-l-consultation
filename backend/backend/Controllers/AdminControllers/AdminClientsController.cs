using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminUsersDto;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminClientsController: ControllerBase
    {
        public readonly IAdminRepo adminRepo;
        public AdminClientsController(IAdminRepo adminRepo)
        {
            this.adminRepo = adminRepo;
        }

        [Authorize]
        [HttpGet]
        [Route("/GetClients")]
        public IActionResult GetAllClients()
        {
            var Clients = adminRepo.GetUsersByRole("Client");
            return Ok(Clients);
        }
        [HttpGet]
        [Route("/GetClientById/{id}")]
        public IActionResult GetClientById(Guid id)
        {
            var client = adminRepo.GetUserById(id);

            if (client == null || client.Role != "Client") 
                return BadRequest(new { message = "Client not found" });
            return Ok(client);
        }
    }
}
