using backend.Data;
using backend.Dtos.AnimalDtos;
using backend.Dtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AnimalRepo;
using backend.Repo.ClientsRepo;
using backend.Repo.Rendez_vousRepo;
using backend.Repo.VetRepo;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [Controller]
    public class Rendez_vousController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IRendezVousRepo _repo;
        public IVetRepo _VetRepo;
        public IClientRepo _ClientRepo;
        public IAnimalRepo _AnimalRepo;
        public Rendez_vousController(AppDbContext context,IRendezVousRepo repo,IVetRepo vetRepo,IClientRepo clientRepo,IAnimalRepo animalRepo)
        {
            _context = context;
            _repo = repo;
            _VetRepo = vetRepo;
            _ClientRepo = clientRepo;
            _AnimalRepo = animalRepo;
        }
        [HttpGet]
        [Route("get-all-rendez-vous")]
        public IActionResult GetAllRendezVous()
        {
            var Rvous = _repo.getAllRendezVous();
            return Ok(Rvous);
        }
        [HttpGet]
        [Route("get-rendez-vous-by-id")]
        public IActionResult GetRendezVousById(Guid id)
        {
            var Rvous = _repo.getRendezVousById(id);
            if (Rvous == null)
            {
                return BadRequest("No rendez-vous with this Id !");
            }
            return Ok(Rvous);
        }

        [HttpGet]
        [Route("get-rendez-vous-by-vet-id/{vetId}")]
        public IActionResult GetRendezVousByVetId(Guid vetId)
        {
            var vet = _context.veterinaires.Where(v => v.AppUserId == vetId);//it should look for the appuser id where the role is vet
            if (vet == null)
                return BadRequest("No veterinaire with this Id !");

            var Rvous = _repo.getRendezVousByVetId(vetId);
            return Ok(Rvous);

        }
        [HttpGet]
        [Route("get-rendez-vous-by-client-id/{clientId}")]
        public IActionResult GetRendezVousByClientId(Guid clientId)
        {
            var client = _context.clients.Where(c => c.AppUserId == clientId);
            if (client == null)
                return BadRequest("No client with this Id !");

            var Rvous = _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);

        }
        [HttpGet]
        [Route("get-rendez-vous-by-animal-id/{animalId}")]
        public IActionResult GetRendezVousByanimalId(Guid animalId)
        {
            var animal = _context.Animals.Find(animalId);
            if (animal == null)
                return BadRequest("No animal with this Id !");

            var Rvous = _repo.getRendezVousByAnimalId(animalId);
            return Ok(Rvous);

        }

        [HttpGet]
        [Route("get-rendez-vous-by-status")]
        public IActionResult GetRendezVousByStatus(RendezVousStatus status)
        {
            var Rvous = _repo.getRendezVousByStatus(status);
            if (Rvous == null)
            {
                return BadRequest("No rendez-vous with this status !");
            }
            return Ok(Rvous);
        }

        [HttpPost]
        [Route("add-rendez-vous")]
        public IActionResult AddRendezVous([FromBody] AddRendezVousDto model)
        {
            var vet = _VetRepo.GetVeterinaireById(model.VetId);
            if (vet == null)
                return NotFound(new { message = "Veterinaire not found." });

            var client = _ClientRepo.GetClientById(model.ClientId);
            if (client == null)
                return NotFound(new { message = "Client not found." });

            var animal = _AnimalRepo.getAnimalById(model.AnimalId);
            if (animal == null)
                return NotFound(new { message = "Animal not found." });

            var rendezVous = new RendezVous
            {
                Date = model.Date.ToUniversalTime(),
                Status = model.Status,
                VeterinaireId = model.VetId,
                ClientId = model.ClientId,
                AnimalId = model.AnimalId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _repo.AddRendezVous(rendezVous);

            return Ok(new { message = "Rendez-vous added successfully", rendezVous });
        }


        [HttpPut]
        [Route("update-rendez-vous/{id}")]
        public IActionResult UpdateRendezVous(Guid id, [FromBody] UpdateRendezVousDto model)
        {
            var rendezVousExist = _context.RendezVous.Find(id);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id doesnt exist !");

            var res= _repo.UpdateRendezVous(id, model);
            return Ok(new { message = res });
        }

        [HttpDelete]
        [Route("delete-rendez-vous/{id}")]
        public IActionResult DeleteAnimal(Guid id)
        {
            var RvousExist = _context.RendezVous.Find(id);
            if (RvousExist == null)
            {
                return BadRequest("Rendez-vous with this Id not found");
            }

            var result = _repo.DeleteRendezVous(id);

            return Ok(new { message = result });
        }

    }
}
