﻿using backend.Data;
using backend.Dtos.ClientDtos.RendezVousDtos;
using backend.Models;
using backend.Repo.AdminRepo.AnimalRepo;
using backend.Repo.AdminRepo.ClientsRepo;
using backend.Repo.AdminRepo.VetRepo;
using backend.Repo.ClientRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[controller]")]
    [ApiController]
    [Authorize(Policy = "Client")]
    public class Rendez_vousCController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IRendezVousCRepo _repo;
        public IClientRepo _clientRepo;
        public IVetRepo _vetRepo;
        public IAnimalRepo _animalRepo;

        public Rendez_vousCController(AppDbContext context, IRendezVousCRepo repo, IClientRepo clientRepo, IVetRepo vetRepo, IAnimalRepo animalRepo)
        {
            _context = context;
            _repo = repo;
            _clientRepo = clientRepo;
            _vetRepo = vetRepo;
            _animalRepo = animalRepo;
        }

        [HttpGet]
        [Route("rendez-vous-list")]
        public async Task<IActionResult> RendezVousList()
        {
            var idClaim = User.FindFirst("Id");
            foreach (var claim in User.Claims)
            {
                Console.WriteLine($"Claim: {claim.Type} = {claim.Value}");
            }


            if (idClaim == null || string.IsNullOrWhiteSpace(idClaim.Value))
            {
                throw new UnauthorizedAccessException("User ID claim is missing.");
            }

            var clientId = Guid.Parse(idClaim.Value);
            var Rvous =await _repo.getRendezVousByClientId(clientId);
            return Ok(Rvous);
        }
        [HttpPost]
        [Route("add-rendez-vous")]
        public async Task<IActionResult> AddRendezVous([FromBody] AddRendezVousClientDto model)
        {
            if (model == null)
            {
                return BadRequest(new { message = "Invalid data" });
            }

            // Retrieve the ClientId from the claims
            var idClaimValue = User.FindFirst("Id")?.Value;
            if (string.IsNullOrEmpty(idClaimValue) || !Guid.TryParse(idClaimValue, out var clientId))
            {
                return Unauthorized(new { message = "Invalid or missing user ID claim." });
            }

            // Check if the client exists
            var client = await _clientRepo.GetClientByIdAsync(clientId);
            if (client == null)
            {
                return NotFound(new { message = "Client not found." });
            }

            // Check if the veterinarian exists
            var vet = await _vetRepo.GetVeterinaireById(model.VetId);
            if (vet == null)
            {
                return NotFound(new { message = "Veterinaire not found." });
            }

            // Check if the animal exists and belongs to the client
            var animal = await _context.Animals.FirstOrDefaultAsync(a => a.Id == model.AnimalId && a.OwnerId == clientId);
            if (animal == null)
            {
                return NotFound(new { message = "Animal not found." });
            }

            // Map DTO to entity
            var rendezVous = new RendezVous
            {
                Date = model.Date.ToUniversalTime(),
                Status = RendezVousStatus.Confirmé, // Default status, can be modified if needed
                VeterinaireId = model.VetId,
                ClientId = clientId,
                AnimalId = model.AnimalId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // Add to database via service method
            var result = await _repo.AddRendezVous(rendezVous);

            if (result == "Rendez-vous added successfully")
            {
                return Ok(new { message = "Rendez-vous added successfully", rendezVous });
            }

            return BadRequest(new { message = result });
        }


        [HttpPut]
        [Route("update-rendez-vous/{id}")]
        public async Task<IActionResult> UpdateRendezVous(Guid id, [FromBody] UpdateRendezVousClientDto model)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var rendezVousExist =await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesn't exist!");

            var vet =await _context.veterinaires.FirstOrDefaultAsync(u => u.AppUserId == model.VetId);
            if (vet == null)
                return BadRequest("Veterinaire not found.");

            var animal = await _context.Animals.FirstOrDefaultAsync(u => u.Id == model.AnimalId && u.OwnerId == clientId);
            if (animal == null)
                return BadRequest("Animal not found.");

            rendezVousExist.Date = model.Date.ToUniversalTime();
            rendezVousExist.VeterinaireId = model.VetId;
            rendezVousExist.AnimalId = model.AnimalId;
            rendezVousExist.UpdatedAt = DateTime.UtcNow;

            _context.RendezVous.Update(rendezVousExist);
            await _repo.SaveChanges();

            return Ok("Rendez-vous updated successfully");
        }

        [HttpDelete]
        [Route("delete-rendez-vous/{id}")]
        public async Task<IActionResult> DeleteRendezVous(Guid id)
        {
            var idClaimValue = User.FindFirst("Id")?.Value;

            if (!Guid.TryParse(idClaimValue, out var clientId))
            {
                throw new UnauthorizedAccessException("Invalid or missing user ID claim.");
            }

            var rendezVousExist =await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == id && r.ClientId == clientId);
            if (rendezVousExist == null)
                return BadRequest("Rendez-vous with this id for this client doesn't exist!");

            var result =await _repo.DeleteRendezVous(id);
            return Ok(result);
        }
    }

}

