using backend.Data;
using backend.Dtos.RendezVousDtos;
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
        public IEnumerable<RendezVous> getRendezVousByVetId()
        {
            throw new NotImplementedException();
        }
        public IEnumerable<RendezVous> getRendezVousByClientId()
        {
            throw new NotImplementedException();
        }
        public IEnumerable<RendezVous> getRendezVousByAnimalId()
        {
            throw new NotImplementedException();
        }

        public IEnumerable<RendezVous> getRendezVousByDate()
        {
            throw new NotImplementedException();
        }

        public IEnumerable<RendezVous> getRendezVousByStatus()
        {
            throw new NotImplementedException();
        }

        public string AddRendezVous(RendezVous rendezVous)
        {
            throw new NotImplementedException();
        }
        public string UpdateRendezVous(Guid id, UpdateRendezVousDto updatedRendezVous)
        {
            throw new NotImplementedException();
        }
        public string DeleteRendezVous(Guid id)
        {
            throw new NotImplementedException();
        }

        public void SaveChanges()
        {
            throw new NotImplementedException();
        }
    }
}
