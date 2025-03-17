using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using backend.Models;

namespace backend.Data
{
    public class AppDbContext : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>  
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<AppUser> AppUsers { get; set; }
        public DbSet<ApplicationRole> ApplicationRole { get; set; }
        public DbSet<Animal> Animals { get; set; }
        public DbSet<Vaccination> Vaccinations { get; set; }
        public DbSet<CategorieProd> Categories { get; set; }
        public DbSet<Commande> Commandes { get; set; }
        public DbSet<Consultation> Consultations { get; set; }
        public DbSet<Paiement> Paiements { get; set; }
        public DbSet<Produit> Produits { get; set; }
        public DbSet<RendezVous> RendezVous { get; set; }


        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.Entity<IdentityUserRole<Guid>>()
                .HasKey(r => new { r.UserId, r.RoleId });

            builder.Entity<IdentityUserRole<Guid>>()
                .HasOne<AppUser>()
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .IsRequired();

            builder.Entity<IdentityUserRole<Guid>>()
                .HasOne<ApplicationRole>()
                .WithMany()
                .HasForeignKey(r => r.RoleId)
                .IsRequired();
        }

    }



}
