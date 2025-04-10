using backend.Data;
using backend.Dtos.ClientDtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AdminRepo.AnimalRepo;
using backend.Repo.AdminRepo.ClientsRepo;
using backend.Repo.AdminRepo.VetRepo;
using backend.Repo.ClientRepo.RendezVousRepo;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
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
        [Route("rendez-vous-list/{clientId}")]
        public IActionResult RendezVousList(Guid clientId)
        {
            var Rvous = _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);
        }
        [HttpPost]
        [Route("add-rendez-vous/{clientId}")]
        public IActionResult AddRendezVous(Guid clientId, [FromBody] AddRendezVous model)
        {
            var client = _clientRepo.GetClientById(clientId);
            if (client == null)
                return NotFound(new { message = "Client not found." });

            var vet = _vetRepo.GetVeterinaireById(model.VetId);
            if (vet == null)
                return NotFound(new { message = "Veterinaire not found." });


            var animal = _context.Animals.FirstOrDefault(a => a.Id == model.AnimalId && a.OwnerId == clientId);
            ;
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
        [Route("update-rendez-vous/{clientId}/{id}")]
        public IActionResult UpdateRendezVous(Guid clientId, Guid id, [FromBody] UpdateRendezVous model)
        {
            var rendezVousExist = _context.RendezVous.FirstOrDefault(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesnt exist !");

            var vet = _context.veterinaires.FirstOrDefault(u => u.AppUserId == model.VetId);
            if (vet == null)
                return BadRequest("Veterinaire not found.");

            var animal = _context.Animals.FirstOrDefault(u => u.Id == model.AnimalId);
            if (animal == null)
                return BadRequest("Animal not found.");


            var RvousToUpdate = _context.RendezVous.Find(id);

            if (RvousToUpdate == null)
                return BadRequest("Rendez-vous not found !");

            RvousToUpdate.Date = model.Date.ToUniversalTime();
            RvousToUpdate.VeterinaireId = model.VetId;
            RvousToUpdate.ClientId = clientId;
            RvousToUpdate.AnimalId = model.AnimalId;

            RvousToUpdate.UpdatedAt = DateTime.UtcNow.ToUniversalTime();

            _context.RendezVous.Update(RvousToUpdate);
            _context.SaveChanges();
            return Ok("Rendez-vous updated successfully");
        }

        [HttpDelete]
        [Route("delete-rendez-vous/{clientId}/{id}")]
        public IActionResult DeleteRendezVous(Guid clientId, Guid id)
        {
            var rendezVousExist = _context.RendezVous.FirstOrDefault(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesnt exist !");

            var result = _repo.DeleteRendezVous(id);
            return Ok(result);
        }
    }
}
