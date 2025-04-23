using backend.Repo.ClientRepo.VetRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers.ClientControllers
{
    [Route("api/client/[Controller]")]
    [Controller]
    //[Authorize(Policy = "Client")]
    public class VetsCController : ControllerBase
    {
        public readonly IVetCRepo _vetRepo;
        public VetsCController(IVetCRepo vetCRepo) {
            _vetRepo = vetCRepo;
        }
        [HttpGet]
        [Route("get-all-veterinaires")]
        public async Task<IActionResult> GetAllVeterinaire()
        {
            var veterinaires = await _vetRepo.GetAvailableVets();
            return Ok(veterinaires);
        }
    }
}
