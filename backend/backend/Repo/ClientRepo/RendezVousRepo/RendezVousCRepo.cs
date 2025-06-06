﻿using backend.Data;
using backend.Dtos.ClientDtos.RendezVousDtos;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public class RendezVousCRepo : IRendezVousCRepo
    {
        public AppDbContext _context;
        public RendezVousCRepo(AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<RendezVousCDto>> getRendezVousByClientId(Guid clientId)
        {
            var Rvous = await _context.RendezVous
                .Where(r => r.ClientId == clientId)
                .Include(r => r.Veterinaire)
                .Include(r => r.Animal)
                .Select(r => new RendezVousCDto
                {
                    Id = r.Id,
                    Date = r.Date,
                    VetName = r.Veterinaire.UserName,
                    AnimalName = r.Animal.Nom,
                    Status = r.Status 
                })
                .ToListAsync();

            return Rvous;
        }

        public async Task<string> AddRendezVous(RendezVous rendezVous)
        {
            if (rendezVous == null)
            {
                return "Failed to add rendez-vous: Invalid data.";
            }

            try
            {
                await _context.RendezVous.AddAsync(rendezVous);

                await _context.SaveChangesAsync();

                return "Rendez-vous added successfully";
            }
            catch (Exception ex)
            {
                return $"Failed to add rendez-vous: {ex.Message}";
            }
        }

        public async Task<string> DeleteRendezVous(Guid id)
        {
            var Rvous =await _context.RendezVous.FirstOrDefaultAsync(r => r.Id == id);
            _context.RendezVous.Remove(Rvous);
            await SaveChanges();
            return ("Rendez-vous removed successfully");
        }

        public async Task SaveChanges()
        {
            await _context.SaveChangesAsync();
        }

    }
}
