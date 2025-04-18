using backend.Data;
using backend.Dtos.AdminDtos.AnimalDtos;
using backend.Models;
using backend.Repo.AdminRepo.AnimalRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[controller]")]
    [Controller]
    [Authorize(Policy = "Admin")]

    public class AnimalsController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IAnimalRepo _repo;

        public AnimalsController(AppDbContext context, IAnimalRepo repo)
        {
            _context = context;
            _repo = repo;
        }

        [HttpGet]
        [Route("get-all-animals")]
        public async Task<IActionResult> GetAllAnimals()
        {
            var animals = await _repo.GetAllAnimalsAsync(); 
            return Ok(animals);
        }

        [HttpGet]
        [Route("get-animal-by-id/{id}")]
        public async Task<IActionResult> GetAnimalById(Guid id)
        {
            var animals = await _repo.GetAnimalByIdAsync(id);  
            if (animals == null)
            {
                return BadRequest("No animal with this Id!");
            }
            return Ok(animals);
        }

        [HttpGet]
        [Route("get-animals-by-owner-id/{ownerId}")]
        public async Task<IActionResult> GetAnimalsByOwnerId(Guid ownerId)
        {
            var owner = await _context.AppUsers.FindAsync(ownerId);  
            if (owner == null)
                return BadRequest("No Owner with this Id!");

            var animals = await _repo.GetAnimalsByOwnerIdAsync(ownerId);  
            if (animals == null)
                return BadRequest("No animals for this owner!");
            return Ok(animals);
        }

        [HttpGet]
        [Route("get-animals-by-name/{name}")]
        public async Task<IActionResult> GetAnimalsByname(string name)
        {
            var animals = await _repo.GetAnimalsByNameAsync(name); 
            if (animals == null)
            {
                return BadRequest("No animal with this name!");
            }
            return Ok(animals);
        }

        [HttpGet]
        [Route("get-animals-by-espece/{espece}")]
        public async Task<IActionResult> GetAnimalsByEspece(string espece)
        {
            var animals = await _repo.GetAnimalsByEspeceAsync(espece);
            if (animals == null)
            {
                return BadRequest("No animal in this espece!");
            }
            return Ok(animals);
        }

        [HttpGet]
        [Route("get-animals-by-race/{race}")]
        public async Task<IActionResult> GetAnimalsByRace(string race)
        {
            var animals = await _repo.GetAnimalsByRaceAsync(race);  
            if (animals == null)
            {
                return BadRequest("No animal in this race!");
            }
            return Ok(animals);
        }

        [HttpPost]
        [Route("add-animal")]
        public async Task<IActionResult> AddAnimal([FromBody] AddAnimalAdminDto model)
        {
            var owner = await _context.Users.FirstOrDefaultAsync(u => u.Id == model.OwnerId);  
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
                OwnerId = model.OwnerId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _repo.AddAnimalAsync(animal);  

            return Ok(new { message = "Animal added successfully", animal });
        }

        [HttpPut]
        [Route("update-animal/{id}")]
        public async Task<IActionResult> UpdateAnimal(Guid id, [FromBody] UpdateAnimalAdminDto updatedAnimal)
        {
            var animalExist = await _context.Animals.FindAsync(id);
            if (animalExist == null)
            {
                return BadRequest("Animal not found");
            }

            var result = await _repo.UpdateAnimalAsync(id, updatedAnimal); 

            return Ok(new { message = result });
        }

        [HttpDelete]
        [Route("delete-animal/{id}")]
        public async Task<IActionResult> DeleteAnimal(Guid id)
        {
            var animalExist = await _context.Animals.FindAsync(id);  
            if (animalExist == null)
            {
                return BadRequest("Animal with this Id not found");
            }

            var result = await _repo.DeleteAnimalAsync(id);  

            return Ok(new { message = result });
        }
    }
}
