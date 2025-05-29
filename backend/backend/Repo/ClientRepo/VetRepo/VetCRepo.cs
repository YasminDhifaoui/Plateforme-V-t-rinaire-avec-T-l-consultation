using backend.Data;
using backend.Dtos.ClientDtos.VetDtos;
using Microsoft.EntityFrameworkCore;

namespace backend.Repo.ClientRepo.VetRepo
{
    public class VetCRepo : IVetCRepo
    {
        public readonly AppDbContext _context;

        public VetCRepo (AppDbContext context)
        {
            _context = context;
        }
        public async Task<IEnumerable<VetCDto>> GetAvailableVets()
        {
            var veterinaires = await _context.Users
                 .Where(user => user.Role == "Veterinaire")
                 .Select(user => new VetCDto
                 {
                     Id = user.Id,
                     UserName = user.UserName,
                     Address = user.Address,
                     PhoneNumber = user.PhoneNumber,
                     Email = user.Email

                 }).ToListAsync();
            return veterinaires;

        }
    }
}
