using backend.Data;
using Microsoft.AspNetCore.Mvc;

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
            return Ok(_context.Animals.ToList());
        }

        [HttpPost("addAnimal")]
        public IActionResult addAnimals([FromBody]Animal animal) {
            _context.Animals.Add(animal);
            _context.SaveChanges();
            return Ok();
        }

        [HttpDelete("deleteAnimal{id}")]
        public IActionResult DeleteAnimal(int id) {
            var animal = _context.Animals.Find(id);
            if(User == null)
            {
                return NotFound();
            }
            _context.Animals.Remove(animal);
            _context.SaveChanges();
            return Ok();
        }

        [HttpPut("updateAnimal{id}")]
        public IActionResult updateAnimal(int id, [FromBody]Animal updatedAnimal)
        {
            var Animal = _context.Animals.Find(id);
            if(Animal == null)
            {
                return NotFound();
            }
            Animal.name = updatedAnimal.name;
            Animal.espece = updatedAnimal.espece;
            Animal.race = updatedAnimal.race;
            Animal.age = updatedAnimal.age;
            Animal.sexe = updatedAnimal.sexe;
            Animal.allergies = updatedAnimal.allergies;
            Animal.antecedentsMedicaux = updatedAnimal.antecedentsMedicaux;
            Animal.idProprietaire = updatedAnimal.idProprietaire;
            Animal.vaccination = updatedAnimal.vaccination;

            _context.SaveChanges();
            return Ok();

        }
        [HttpGet("searchAnimal")]
        public IActionResult searchAnimal([FromQuery] string name)
        {
            var animals = _context.Animals.Where(animal => animal.name.Contains(name))
                .ToList();
            return Ok(animals);
        }
    }
   
}
