using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        // Define the tables (DbSet)
        public DbSet<User> Users { get; set; }
        public DbSet<Animal> Animals { get; set; }
        public DbSet<Vaccination> Vaccinations { get; set; }
    }

    // Example Models
    public class User
    {
        public int Id { get; set; }
        public int email { get; set; }
        public string username { get; set; }
        public string password { get; set; }
        public string role { get; set; }
    }

    public class Vaccination
    {
        public int Id { get; set; }
        public string name { get; set; }
        public DateTime date { get; set; }
    }

    public class Animal
    {
        public int Id { set; get; }
        public string name { get; set; }
        public string espece { get; set; }
        public string race { get; set; }
        public int age { get; set; }
        public string sexe { get; set; }
        public string allergies { get; set; }
        public string antecedentsMedicaux { get; set; }
        public List<Vaccination> vaccination { get; set; }

        [ForeignKey("User")]
        public int idProprietaire { get; set; }
    }
}
