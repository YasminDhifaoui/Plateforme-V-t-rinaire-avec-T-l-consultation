using backend.Data;
using backend.Dtos.ClientDtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AdminRepo.AnimalRepo;
using backend.Repo.AdminRepo.ClientsRepo;
using backend.Repo.AdminRepo.VetRepo;
using backend.Repo.ClientRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]
    public class Rendez_vousController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IRendezVousCRepo _repo;
        public IClientRepo _clientRepo;
        public IVetRepo _vetRepo;
        public IAnimalRepo _animalRepo;

        public Rendez_vousController(AppDbContext context, IRendezVousCRepo repo, IClientRepo clientRepo, IVetRepo vetRepo, IAnimalRepo animalRepo)
        {
            _context = context;
            _repo = repo;
            _clientRepo = clientRepo;
            _vetRepo = vetRepo;
            _animalRepo = animalRepo;
        }

        [HttpGet]
        [Route("rendez-vous-list")]
        public IActionResult RendezVousList()
        {
            var idClaim = User.FindFirst("Id");

            if (idClaim == null || string.IsNullOrWhiteSpace(idClaim.Value))
            {
                throw new UnauthorizedAccessException("User ID claim is missing.");
            }

            var clientId = Guid.Parse(idClaim.Value);
            var Rvous = _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);
        }

        [HttpPost]
        [Route("add-rendez-vous")]
        public IActionResult AddRendezVous([FromBody] AddRendezVousClientDto model)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var client = _clientRepo.GetClientById(clientId);
            if (client == null)
                return NotFound(new { message = "Client not found." });

            var vet = _vetRepo.GetVeterinaireById(model.VetId);
            if (vet == null)
                return NotFound(new { message = "Veterinaire not found." });

            var animal = _context.Animals.FirstOrDefault(a => a.Id == model.AnimalId && a.OwnerId == clientId);
            if (animal == null)
                return NotFound(new { message = "Animal not found." });

            var rendezVous = new RendezVous
            {
                Date = model.Date.ToUniversalTime(),
                Status = RendezVousStatus.Confirmé,
                VeterinaireId = model.VetId,
                ClientId = clientId,
                AnimalId = model.AnimalId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _repo.AddRendezVous(rendezVous);

            return Ok(new { message = "Rendez-vous added successfully", rendezVous });
        }

        [HttpPut]
        [Route("update-rendez-vous/{id}")]
        public IActionResult UpdateRendezVous(Guid id, [FromBody] UpdateRendezVousClientDto model)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var rendezVousExist = _context.RendezVous.FirstOrDefault(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesn't exist!");

            var vet = _context.veterinaires.FirstOrDefault(u => u.AppUserId == model.VetId);
            if (vet == null)
                return BadRequest("Veterinaire not found.");

            var animal = _context.Animals.FirstOrDefault(u => u.Id == model.AnimalId && u.OwnerId == clientId);
            if (animal == null)
                return BadRequest("Animal not found.");

            rendezVousExist.Date = model.Date.ToUniversalTime();
            rendezVousExist.VeterinaireId = model.VetId;
            rendezVousExist.AnimalId = model.AnimalId;
            rendezVousExist.UpdatedAt = DateTime.UtcNow;

            _context.RendezVous.Update(rendezVousExist);
            _context.SaveChanges();

            return Ok("Rendez-vous updated successfully");
        }

        [HttpDelete]
        [Route("delete-rendez-vous/{id}")]
        public IActionResult DeleteRendezVous(Guid id)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var rendezVousExist = _context.RendezVous.FirstOrDefault(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesn't exist!");

            var result = _repo.DeleteRendezVous(id);
            return Ok(result);
        }
    }

}

