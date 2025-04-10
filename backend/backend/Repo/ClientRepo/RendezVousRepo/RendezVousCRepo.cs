using backend.Data;
using backend.Models;

namespace backend.Repo.ClientRepo.RendezVousRepo
{
    public class RendezVousCRepo : IRendezVousCRepo
    {
        public AppDbContext _context;
        public RendezVousCRepo(AppDbContext context)
        {
            _context = context;
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
