using backend.Data;
using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;
using backend.Repo.ClientRepo.AnimalRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]

    public class AnimalsController : ControllerBase
    {

        public readonly AppDbContext _context;
        public IAnimalCRepo _repo;
        public AnimalsController(AppDbContext context, IAnimalCRepo repo)
        {

            _context = context;
            _repo = repo;
        }
        [HttpGet]
        [Route("animals-list")]
        public IActionResult AnimalsList()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token");

            Guid userId = Guid.Parse(userIdClaim);
            var animals = _repo.getAnimalsByOwnerId(userId);

            return Ok(animals);
        }
        [HttpPost]
        [Route("add-animal")]
        public IActionResult AddAnimal([FromBody] AddAnimalClientDto model)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var owner = _context.Users.FirstOrDefault(u => u.Id == ownerId);
            if (owner == null)
                return NotFound(new { message = "Owner not found." });

            var animal = new Animal
            {
                Nom = model.Name,
                Espece = model.Espece,
                Race = model.Race,
                Age = model.Age,
                Sexe = model.Sexe,
                Allergies = model.Allergies,
                AnttecedentsMedicaux = model.AntecedentsMedicaux,
                OwnerId = ownerId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _repo.AddAnimal(animal);

            return Ok(new { message = "Animal added successfully", animal });
        }


        [HttpPut]
        [Route("update-animal/{id}")]
        public IActionResult UpdateAnimal(Guid id, [FromBody] UpdateAnimalClientDto updatedAnimal)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var owner = _context.Users.FirstOrDefault(u => u.Id == ownerId);
            if (owner == null)
                return BadRequest("Owner not found.");

            var animalExist = _context.Animals.FirstOrDefault(a => a.Id == id && a.OwnerId == ownerId);
            if (animalExist == null)
                return BadRequest("Animal not found.");

            animalExist.Nom = updatedAnimal.Name;
            animalExist.Age = updatedAnimal.Age;
            animalExist.Allergies = updatedAnimal.Allergies;
            animalExist.AnttecedentsMedicaux = updatedAnimal.AntecedentsMedicaux; // ← fixed from using old value

            animalExist.UpdatedAt = DateTime.UtcNow;

            _context.Animals.Update(animalExist);
            _context.SaveChanges();

            return Ok("Animal updated successfully");
        }

        [HttpDelete]
        [Route("delete-animal/{id}")]
        public IActionResult DeleteAnimal(Guid id)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var animalExist = _context.Animals.FirstOrDefault(a => a.Id == id && a.OwnerId == ownerId);
            if (animalExist == null)
                return BadRequest("Animal not found.");

            var result = _repo.deleteAnimal(id);

            return Ok(new { message = result });
        }


    }
}
