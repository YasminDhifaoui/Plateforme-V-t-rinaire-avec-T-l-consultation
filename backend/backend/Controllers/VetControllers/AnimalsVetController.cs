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
    public async Task<IActionResult> AnimalsList()
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);
        var animals = await _animalRepo.GetAnimalsByVetId(vetId);

        if (animals == null || !animals.Any())
            return NotFound(new { message = "No animals found for this veterinarian." });

        return Ok(animals);
    }

    [HttpGet("client/{clientId}")]
    public async Task<IActionResult> GetAnimalsByClientId(Guid clientId)
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

        var animals = await _animalRepo.GetAnimalsByClientIdAndVetIdAsync(vetId, clientId);

        if (animals == null || !animals.Any())
            return NotFound(new { message = "No animals found for this client under your care." });

        return Ok(animals);
    }



    [HttpPut]
    [Route("update-animal/{id}")]
    public async Task<IActionResult> UpdateAnimal(Guid id, [FromBody] UpdateAnimalVetDto model)
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

        var rendezVous =await _rendezVousRepo.GetRendezVousByAnimalIdAndVetId(id, vetId);
        if (rendezVous == null)
            return BadRequest("This animal did not have a rendez-vous with this veterinarian.");

        var result = await _animalRepo.UpdateAnimalAsync(vetId, id, model);

        if (result == "Animal not found." || result == "Vet Id not found.")
            return NotFound(new { message = result });

        return Ok(new { message = result });
    }

}
