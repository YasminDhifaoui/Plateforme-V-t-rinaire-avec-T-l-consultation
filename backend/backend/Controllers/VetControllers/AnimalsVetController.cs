using backend.Data;
using backend.Dtos.VetDtos.AnimalDtos;
using backend.Repo.VetRepo.AnimalRepo;
using backend.Repo.VetRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Route("api/veterinaire/[controller]")]
[ApiController]
[Authorize(Policy = "Veterinaire")]
public class AnimalsVetController : ControllerBase
{
    public readonly AppDbContext _context;
    public IRendezVousVRepo _rendezVousRepo;
    public IAnimalVRepo _animalRepo;

    public AnimalsVetController(AppDbContext context, IRendezVousVRepo rendezVousRepo, IAnimalVRepo animalRepo)
    {
        _context = context;
        _rendezVousRepo = rendezVousRepo;
        _animalRepo = animalRepo;
    }

    [HttpGet]
    [Route("animals-list")]
    public IActionResult AnimalsList()
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

        var animals = _animalRepo.GetAnimalsByVetId(vetId);
        if (animals == null || !animals.Any())
            return NotFound(new { message = "No animals found for this veterinarian." });

        return Ok(animals);
    }

    [HttpPut]
    [Route("update-animal/{id}")]
    public IActionResult UpdateAnimal(Guid id, [FromBody] UpdateAnimalVetDto model)
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

        var rendezVous = _rendezVousRepo.GetRendezVousByAnimalIdAndVetId(id, vetId);
        if (rendezVous == null)
            return BadRequest("This animal did not have a rendez-vous with this veterinarian.");

        var animal = _context.Animals.FirstOrDefault(a => a.Id == id);
        if (animal == null)
            return BadRequest("Animal not found.");

        animal.Age = model.Age ;
        animal.Allergies = model.Allergies ?? animal.Allergies;
        animal.AnttecedentsMedicaux = model.AntecedentsMedicaux ?? animal.AnttecedentsMedicaux;

        animal.UpdatedAt = DateTime.UtcNow;

        _context.Animals.Update(animal);
        _context.SaveChanges();

        return Ok(new { message = "Animal information updated successfully", animal });
    }
}
