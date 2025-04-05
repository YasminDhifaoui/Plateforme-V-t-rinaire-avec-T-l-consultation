using backend.Data;
using backend.Dtos.AnimalDtos;
using backend.Models;
using backend.Repo.AnimalRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [Controller]
    public class AnimalsController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IAnimalRepo _repo;
        public AnimalsController(AppDbContext context, IAnimalRepo repo) {

            _context = context;
            _repo = repo;
        }

        [HttpGet]
        [Route("get-all-animals")]
        public IActionResult GetAllAnimals()
        {
            var animals = _repo.getAllAnimals();
            return Ok(animals);

        }

        [HttpGet]
        [Route("get-animal-by-id/{id}")]
        public IActionResult GetAnimalById(Guid id)
        {
            var animals = _repo.getAnimalById(id);
            if (animals == null)
            {
                return BadRequest("No animal with this Id !");
            }
            return Ok(animals);

        }

        [HttpGet]
        [Route("get-animals-by-owner-id/{ownerId}")]
        public IActionResult GetAnimalsByOwnerId(Guid ownerId)
        {
            var owner = _context.AppUsers.Find(ownerId);
            if (owner == null)
                return BadRequest("No Owner with this Id !");

            var animals = _repo.getAnimalsByOwnerId(ownerId);
            return Ok(animals);

        }
       
        [HttpGet]
        [Route("get-animals-by-name/{name}")]
        public IActionResult GetAnimalsByname(string name)
        {
            var animals = _repo.getAnimalsByName(name);
            if (animals == null)
            {
                return BadRequest("No animal with this name !");
            }
            return Ok(animals);

        }
        [HttpGet]
        [Route("get-animals-by-espece/{espece}")]
        public IActionResult GetAnimalsByEspece(string espece)
        {
            var animals = _repo.getAnimalsByEspece(espece);
            if (animals == null)
            {
                return BadRequest("No animal in this espece !");
            }
            return Ok(animals);

        }
        [HttpGet]
        [Route("get-animals-by-race/{race}")]
        public IActionResult GetAnimalsByRace(string race)
        {
            var animals = _repo.getAnimalsByRace(race);
            if (animals == null)
            {
                return BadRequest("No animal in this race !");
            }
            return Ok(animals);

        }
        [HttpPut]
        [Route("add-animal")]
        public IActionResult AddAnimal([FromBody] AddAnimalDto model)
        {
            var owner = _context.Users.FirstOrDefault(u => u.Id == model.OwnerId);
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

            _repo.AddAnimal(animal);

            return Ok(new { message = "Animal added successfully", animal });
        }
        [HttpPut]
        [Route("update-animal/{id}")]
        public IActionResult UpdateAnimal(Guid id, [FromBody] UpdateAnimalDto updatedAnimal)
        {
            var animalExist = _context.Animals.Find(id);
            if (animalExist == null)
            {
                return BadRequest("Animal not found");
            }

            var result = _repo.UpdateAnimal(id, updatedAnimal);

            return Ok(new { message = result});
        }
        [HttpDelete]
        [Route("delete-animal/{id}")]
        public IActionResult DeleteAnimal(Guid id)
        {
            var animalExist = _context.Animals.Find(id);
            if (animalExist == null)
            {
                return BadRequest("Animal with this Id not found");
            }

            var result = _repo.deleteAnimal(id);

            return Ok(new { message = result });
        }


    }
}
