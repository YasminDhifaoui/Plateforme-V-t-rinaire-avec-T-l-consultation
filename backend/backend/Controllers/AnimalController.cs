using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AnimalController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AnimalController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("animalList")]
        public IActionResult GetAnimals()
        {
            var animals = _context.Animals
                .ToList();
            return Ok(animals);
        }

        [HttpPost("addAnimal")]
        public IActionResult AddAnimal([FromBody] Animal animal)
        {
            if (animal == null)
            {
                return BadRequest("Animal data is required.");
            }

            animal.CreatedAt = DateTime.UtcNow;
            animal.UpdatedAt = DateTime.UtcNow;

            _context.Animals.Add(animal);
            _context.SaveChanges();

            return Ok(new { message = "Animal added successfully." });
        }

        [HttpDelete("deleteAnimal/{id}")]
        public IActionResult DeleteAnimal(int id)
        {
            var animal = _context.Animals.Find(id);
            if (animal == null)
            {
                return NotFound(new { message = "Animal not found." });
            }

            _context.Animals.Remove(animal);
            _context.SaveChanges();

            return Ok(new { message = "Animal deleted successfully." });
        }

        [HttpPut("updateAnimal/{id}")]
        public IActionResult UpdateAnimal(int id, [FromBody] Animal updatedAnimal)
        {
            var animal = _context.Animals.Find(id);
            if (animal == null)
            {
                return NotFound(new { message = "Animal not found." });
            }

           /* animal.Name = updatedAnimal.Name;
            animal.Species = updatedAnimal.Species;
            animal.Breed = updatedAnimal.Breed;
            animal.Age = updatedAnimal.Age;
            animal.Sex = updatedAnimal.Sex;
            animal.Allergies = updatedAnimal.Allergies;
            animal.MedicalHistory = updatedAnimal.MedicalHistory;*/


            animal.UpdatedAt = DateTime.UtcNow; 

            _context.SaveChanges();
            return Ok(new { message = "Animal updated successfully." });
        }

        [HttpGet("searchAnimal")]
        public IActionResult SearchAnimal([FromQuery] string name)
        {
           /* var animals = _context.Animals
                .Where(a => a.Name.Contains(name))
                .ToList();

            if (animals.Count == 0)
            {
                return NotFound(new { message = "No animals found with the given name." });
            }*/

            return Ok(/*animals*/);
        }
    }
}
