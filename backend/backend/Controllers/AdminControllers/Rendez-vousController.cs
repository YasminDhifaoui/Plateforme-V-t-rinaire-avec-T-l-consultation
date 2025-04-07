using backend.Data;
using backend.Repo.Rendez_vousRepo;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [Controller]
    public class Rendez_vousController : ControllerBase
    {
        public readonly AppDbContext _context;
        public IRendezVousRepo _repo;
        public Rendez_vousController(AppDbContext context,IRendezVousRepo repo)
        {
            _context = context;
            _repo = repo;
        }
        [HttpDelete]
        [Route("get-all-rendez-vous")]
        public IActionResult GetAllRendezVous()
        {
            var Rvous = _repo.getAllRendezVous();
            return Ok(Rvous);
        }

    }
}
