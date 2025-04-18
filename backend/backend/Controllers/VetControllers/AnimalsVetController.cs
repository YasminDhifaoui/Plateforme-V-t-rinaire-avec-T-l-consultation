using backend.Data;
using backend.Dtos.VetDtos.AnimalDtos;
using backend.Repo.VetRepo.AnimalRepo;
using backend.Repo.VetRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Route("api/veterinaire/[controller]")]
[ApiController]
[Authorize(Policy = "Veterinaire")]
//Beare eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9lbWFpbGFkZHJlc3MiOiJ5YXNtaW5nYXJnb3VyaTA0QGdtYWlsLmNvbSIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWUiOiJWZXRlci4xIiwiaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93cy8yMDA4LzA2L2lkZW50aXR5L2NsYWltcy9yb2xlIjoiVmV0ZXJpbmFpcmUiLCJqdGkiOiI5NDU1YjYwMy1jZWYxLTRlNDctYTY0NC1iYWZmZTFhNGVkYTEiLCJzdWIiOiJWZXRlci4xIiwiYXVkIjpbImh0dHBzOi8vbG9jYWxob3N0OjcwMDAiLCJodHRwczovL2xvY2FsaG9zdDo3MDAwIl0sImlzcyI6Imh0dHBzOi8vbG9jYWxob3N0OjcwMDAiLCJJZCI6IjVjNjgwMzA1LTc5YTAtNGIwMy1iOGE5LWNjOWExN2E2M2JhNyIsImV4cCI6MTc0NTAxODg5NH0.f0EWYKzsv2v1cS-aeOJvC9DyfZE9rn8Yoqh2dqwsLc4
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


    [HttpPut]
    [Route("update-animal/{id}")]
    public async Task<IActionResult> UpdateAnimal(Guid id, [FromBody] UpdateAnimalVetDto model)
    {
        var vetId = Guid.Parse(User.FindFirst("Id")?.Value);

        var rendezVous = _rendezVousRepo.GetRendezVousByAnimalIdAndVetId(id, vetId);
        if (rendezVous == null)
            return BadRequest("This animal did not have a rendez-vous with this veterinarian.");

        var result = await _animalRepo.UpdateAnimalAsync(vetId, id, model);

        if (result == "Animal not found." || result == "Vet Id not found.")
            return NotFound(new { message = result });

        return Ok(new { message = result });
    }

}
