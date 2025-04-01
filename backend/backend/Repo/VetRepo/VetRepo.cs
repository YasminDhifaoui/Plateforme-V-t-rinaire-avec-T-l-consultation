using backend.Data;
using backend.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.VetRepo
{
    public class VetRepo : IVetRepo
    {
        public readonly AppDbContext _context;
        public VetRepo(AppDbContext context)
        {
            _context = context;
        }
        public string AddVeterinaire(Veterinaire veterinaire)
        {
            _context.veterinaires.Add(veterinaire);
            this.SaveChanges();
            return "Veterinaire added successfully";
        }

        public void SaveChanges()
        {
            _context.SaveChanges();
        }
    }
}
