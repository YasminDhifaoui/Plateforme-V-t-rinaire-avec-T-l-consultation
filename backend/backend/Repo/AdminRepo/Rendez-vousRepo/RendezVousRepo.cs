using backend.Data;
using backend.Dtos.AdminDtos.RendezVousDtos;
using backend.Models;

namespace backend.Repo.Rendez_vousRepo
{
    public class RendezVousRepo : IRendezVousRepo
    {
        public AppDbContext _context;
        public RendezVousRepo(AppDbContext context) { 
            _context = context;
        }
        public IEnumerable<RendezVous> getAllRendezVous()
        {
            var Rvous = _context.RendezVous.Select(r => new RendezVous
            {
                Id = r.Id,
                Date = r.Date,
                Veterinaire = r.Veterinaire,
                Client = r.Client,
                Animal = r.Animal,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt,
            }).ToList();
            return Rvous;
        }
        public IEnumerable<RendezVous> getRendezVousById(Guid id)
        {
            var Rvous = _context.RendezVous
                .Where(r => r.Id == id)
                .Select(r => new RendezVous
            {
                Id = r.Id,
                Date = r.Date,
                Veterinaire = r.Veterinaire,
                Client = r.Client,
                Animal = r.Animal,
                Status = r.Status,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt,
            }).ToList();
            return Rvous;
        }
        public IEnumerable<RendezVous> getRendezVousByVetId(Guid vetId)
        {
            var Rvous = _context.RendezVous
                .Where(r => r.VeterinaireId == vetId)
                .Select(r => new RendezVous
                {
                    Id = r.Id,
                    Date = r.Date,
                    Veterinaire = r.Veterinaire,
                    Client = r.Client,
                    Animal = r.Animal,
                    Status = r.Status,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt,
                }).ToList();
            return Rvous;
        }
        public IEnumerable<RendezVous> getRendezVousByClientId(Guid clientId)
        {
            var Rvous = _context.RendezVous
                            .Where(r => r.ClientId == clientId)
                            .Select(r => new RendezVous
                            {
                                Id = r.Id,
                                Date = r.Date,
                                Veterinaire = r.Veterinaire,
                                Client = r.Client,
                                Animal = r.Animal,
                                Status = r.Status,
                                CreatedAt = r.CreatedAt,
                                UpdatedAt = r.UpdatedAt,
                            }).ToList();
            return Rvous;
        }
        public IEnumerable<RendezVous> getRendezVousByAnimalId(Guid animalId)
        {
            var Rvous = _context.RendezVous
                            .Where(r => r.AnimalId == animalId)
                            .Select(r => new RendezVous
                            {
                                Id = r.Id,
                                Date = r.Date,
                                Veterinaire = r.Veterinaire,
                                Client = r.Client,
                                Animal = r.Animal,
                                Status = r.Status,
                                CreatedAt = r.CreatedAt,
                                UpdatedAt = r.UpdatedAt,
                            }).ToList();
            return Rvous;
        }


        public IEnumerable<RendezVous> getRendezVousByStatus(RendezVousStatus status)
        {
            var Rvous = _context.RendezVous
                            .Where(r => r.Status == status)
                            .Select(r => new RendezVous
                            {
                                Id = r.Id,
                                Date = r.Date,
                                Veterinaire = r.Veterinaire,
                                Client = r.Client,
                                Animal = r.Animal,
                                Status = r.Status,
                                CreatedAt = r.CreatedAt,
                                UpdatedAt = r.UpdatedAt,
                            }).ToList();
            return Rvous;
        }

        public string AddRendezVous(RendezVous rendezVous)
        {
            if (rendezVous != null)
            {
                _context.RendezVous.Add(rendezVous);
                this.SaveChanges();
                return "Rendez-vous added successfully";
            }
            return "failed to add rendez-vous";
        }

        public string UpdateRendezVous(Guid id, UpdateRendezVousAdminDto updatedRendezVous)
        {
            var vet = _context.veterinaires.FirstOrDefault(u => u.AppUserId == updatedRendezVous.VetId);
            if (vet == null)
                return ("Veterinaire not found." );

            var client = _context.clients.FirstOrDefault(u => u.AppUserId == updatedRendezVous.ClientId);
            if (client == null)
                return ("Client not found.");

            var animal = _context.Animals.FirstOrDefault(u => u.Id == updatedRendezVous.AnimalId);
            if (animal == null)
                return ("Animal not found.");


            var RvousToUpdate = _context.RendezVous.Find(id);

            if (RvousToUpdate == null)
                return "Rendez-vous not found !";

            RvousToUpdate.Date = updatedRendezVous.Date.ToUniversalTime();
            RvousToUpdate.Status = updatedRendezVous.Status;
            RvousToUpdate.VeterinaireId = updatedRendezVous.VetId;
            RvousToUpdate.ClientId = updatedRendezVous.ClientId;
            RvousToUpdate.AnimalId = updatedRendezVous.AnimalId;

            RvousToUpdate.UpdatedAt = DateTime.UtcNow.ToUniversalTime();

            _context.RendezVous.Update(RvousToUpdate);
            this.SaveChanges();
            return "Rendez-vous updated successfully";
        }
        public string DeleteRendezVous(Guid id)
        {
            var Rvous = _context.RendezVous.FirstOrDefault(r => r.Id == id);
            _context.RendezVous.Remove(Rvous);
            this.SaveChanges();
            return ("Rendez-vous removed successfully");
        }

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
