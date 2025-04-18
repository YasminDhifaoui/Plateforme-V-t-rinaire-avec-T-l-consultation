using backend.Data;
using backend.Dtos.AdminDtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AdminRepo.AnimalRepo;
using backend.Repo.AdminRepo.ClientsRepo;
using backend.Repo.AdminRepo.VetRepo;
using backend.Repo.Rendez_vousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[controller]")]
    [Controller]
    //[Authorize(Policy = "Admin")]

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
        public async Task<IActionResult> GetAllRendezVous()
        {
            var Rvous = await _repo.getAllRendezVous();
            return Ok(Rvous);
        }
        [HttpGet]
        [Route("get-rendez-vous-by-id")]
        public async Task<IActionResult> GetRendezVousById(Guid id)
        {
            var Rvous = await _repo.getRendezVousById(id);
            if (Rvous == null)
            {
                return BadRequest("No rendez-vous with this Id !");
            }
            return Ok(Rvous);
        }

        [HttpGet]
        [Route("get-rendez-vous-by-vet-id/{vetId}")]
        public async Task<IActionResult> GetRendezVousByVetId(Guid vetId)
        {
            var vet = await _VetRepo.GetVeterinaireById(vetId); //it should look for the appuser id where the role is vet
            if (vet == null)
                return BadRequest("No veterinaire with this Id !");

            var Rvous = await _repo.getRendezVousByVetId(vetId);
            return Ok(Rvous);

        }
        [HttpGet]
        [Route("get-rendez-vous-by-client-id/{clientId}")]
        public async Task<IActionResult> GetRendezVousByClientId(Guid clientId)
        {
            var client = await _ClientRepo.GetClientByIdAsync(clientId);
            if (client == null)
                return BadRequest("No client with this Id !");

            var Rvous = await _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);

        }
        [HttpGet]
        [Route("get-rendez-vous-by-animal-id/{animalId}")]
        public async Task<IActionResult> GetRendezVousByanimalId(Guid animalId)
        {
            var animal = await _AnimalRepo.GetAnimalByIdAsync(animalId);
            if (animal == null)
                return BadRequest("No animal with this Id !");

            var Rvous = await _repo.getRendezVousByAnimalId(animalId);
            return Ok(Rvous);

        }

        [HttpGet]
        [Route("get-rendez-vous-by-status")]
        public async Task<IActionResult> GetRendezVousByStatus(RendezVousStatus status)
        {
            var Rvous = await _repo.getRendezVousByStatus(status);
            if (Rvous == null)
            {
                return BadRequest("No rendez-vous with this status !");
            }
            return Ok(Rvous);
        }

        [HttpPost]
        [Route("add-rendez-vous")]
        public async Task<IActionResult> AddRendezVous([FromBody] AddRendezVousAdminDto model)
        {
            var vet = await _VetRepo.GetVeterinaireById(model.VetId);
            if (vet == null)
                return NotFound(new { message = "Veterinaire not found." });

            var client = await _ClientRepo.GetClientByIdAsync(model.ClientId);
            if (client == null)
                return NotFound(new { message = "Client not found." });

            var animal = await _AnimalRepo.GetAnimalByIdAsync(model.AnimalId);
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

            await _repo.AddRendezVous(rendezVous);

            return Ok(new { message = "Rendez-vous added successfully", rendezVous });
        }


        [HttpPut]
        [Route("update-rendez-vous/{id}")]
        public async Task<IActionResult> UpdateRendezVous(Guid id, [FromBody] UpdateRendezVousAdminDto model)
        {
            var rendezVousExist = await _repo.getRendezVousById(id);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id doesnt exist !");

            var res= await _repo.UpdateRendezVous(id, model);
            return Ok(new { message = res });
        }

        [HttpDelete]
        [Route("delete-rendez-vous/{id}")]
        public async Task<IActionResult> DeleteAnimal(Guid id)
        {
            var RvousExist = await _repo.getRendezVousById(id);
            if (RvousExist == null)
            {
                return BadRequest("Rendez-vous with this Id not found");
            }

            var result = await _repo.DeleteRendezVous(id);
            

            return Ok(new { message = result });
        }

    }
}
