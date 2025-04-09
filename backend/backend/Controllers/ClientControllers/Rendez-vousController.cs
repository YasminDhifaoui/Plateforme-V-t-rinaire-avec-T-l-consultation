using backend.Data;
using backend.Dtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AnimalRepo;
using backend.Repo.ClientsRepo;
using backend.Repo.Rendez_vousRepo;
using backend.Repo.VetRepo;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    public class Rendez_vousController : ControllerBase
    {

        public readonly AppDbContext _context;
        public IRendezVousRepo _repo;

        public Rendez_vousController(AppDbContext context, IRendezVousRepo repo)
        {
            _context = context;
            _repo = repo;
        }
        [HttpGet]
        [Route("rendez-vous-list/{clientId}")]
        public IActionResult RendezVousList(Guid clientId)
        {
            var Rvous = _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);
        }
    }
}
