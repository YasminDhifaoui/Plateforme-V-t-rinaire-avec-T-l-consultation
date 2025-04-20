using backend.Data;
using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;
using backend.Repo.ClientRepo.AnimalRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]

    public class AnimalsCController : ControllerBase
    {

        public readonly AppDbContext _context;
        public IAnimalCRepo _repo;
        public AnimalsCController(AppDbContext context, IAnimalCRepo repo)
        {

            _context = context;
            _repo = repo;
        }
        [HttpGet]
        [Route("animals-list")]
        public async Task<IActionResult> AnimalsList()
        {
            var userIdClaim = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(userIdClaim, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            if (string.IsNullOrEmpty(userIdClaim))
                return Unauthorized("User ID not found in token");

            Guid userId = Guid.Parse(userIdClaim);
            var animals =await _repo.getAnimalsByOwnerId(userId);

            return Ok(animals);
        }
        [HttpPost]
        [Route("add-animal")]
        public async Task<IActionResult> AddAnimal([FromBody] AddAnimalClientDto model)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var owner =await _context.Users.FirstOrDefaultAsync(u => u.Id == ownerId);
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

            await _repo.AddAnimal(animal);

            return Ok(new { message = "Animal added successfully", animal });
        }


        [HttpPut]
        [Route("update-animal/{id}")]
        public async Task<IActionResult> UpdateAnimal(Guid id, [FromBody] UpdateAnimalClientDto updatedAnimal)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var owner =await _context.Users.FirstOrDefaultAsync(u => u.Id == ownerId);
            if (owner == null)
                return BadRequest("Owner not found.");

            var animalExist =await _context.Animals.FirstOrDefaultAsync(a => a.Id == id && a.OwnerId == ownerId);
            if (animalExist == null)
                return BadRequest("Animal not found.");

            animalExist.Nom = updatedAnimal.Name;
            animalExist.Age = updatedAnimal.Age;
            animalExist.Allergies = updatedAnimal.Allergies;
            animalExist.AnttecedentsMedicaux = updatedAnimal.AntecedentsMedicaux; 

            animalExist.UpdatedAt = DateTime.UtcNow;

            _context.Animals.Update(animalExist);
            await _repo.SaveChanges();

            return Ok("Animal updated successfully");
        }

        [HttpDelete]
        [Route("delete-animal/{id}")]
        public async Task<IActionResult> DeleteAnimal(Guid id)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var ownerId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var animalExist =await _context.Animals.FirstOrDefaultAsync(a => a.Id == id && a.OwnerId == ownerId);
            if (animalExist == null)
                return BadRequest("Animal not found.");

            var result =await _repo.deleteAnimal(id);

            return Ok(new { message = result });
        }


    }
}
