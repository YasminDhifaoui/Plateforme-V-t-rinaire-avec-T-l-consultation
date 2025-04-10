using backend.Data;
using backend.Dtos.ClientDtos.AnimalDtos;
using backend.Models;
using backend.Repo.ClientRepo.AnimalRepo;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
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
        [Route("animals-list{id}")]
        public IActionResult AnimalsList(Guid id)
        {
            var animals = _repo.getAnimalsByOwnerId(id);
            return Ok(animals);

        }
        [HttpPost]
        [Route("add-animal{ownerId}")]
        public IActionResult AddAnimal(Guid ownerId, [FromBody] AddAnimal model)
        {
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
        [Route("update-animal/{ownerId}/{id}")]
        public IActionResult UpdateAnimal(Guid ownerId, Guid id, [FromBody] UpdateAnimal updatedAnimal)
        {

            var owner = _context.Users.FirstOrDefault(u => u.Id == ownerId);
            if (owner == null)
                return BadRequest("Owner with this Id not found.");

            var animalExist = _context.Animals.FirstOrDefault(a => a.Id == id && a.OwnerId == ownerId);
            ;
            if (animalExist == null)
            {
                return BadRequest("Animal not found");
            }

            var animalToUpdate = _context.Animals.Find(id);

            if (animalToUpdate == null)
                return BadRequest("Animal not found !");

            animalToUpdate.Nom = updatedAnimal.Name;
            animalToUpdate.Age = updatedAnimal.Age;
            animalToUpdate.Allergies = updatedAnimal.Allergies;
            animalToUpdate.AnttecedentsMedicaux = animalToUpdate.AnttecedentsMedicaux;

            animalToUpdate.UpdatedAt = DateTime.UtcNow.ToUniversalTime();

            _context.Animals.Update(animalToUpdate);
            _context.SaveChanges();
            return Ok("Animal updated successfully");
        }

        [HttpDelete]
        [Route("delete-animal/{ownerId}/{id}")]
        public IActionResult DeleteAnimal(Guid ownerId , Guid id)
        {
            var animalExist = _context.Animals.FirstOrDefault(a => a.Id == id && a.OwnerId == ownerId);
            if (animalExist == null)
            {
                return BadRequest("Animal not found");
            }

            var result = _repo.deleteAnimal(id);

            return Ok(new { message = result });
        }


    }
}
