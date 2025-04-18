using backend.Data;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.AdminDtos.VetDtos;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo.VetRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[Controller]")]
    [Controller]
    [Authorize(Policy = "Admin")]

    public class VeterinairesController : ControllerBase
    {
        public readonly IVetRepo _vetRepo;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly AppDbContext _context;
        private readonly ILogger<VeterinairesController> _logger;
        private readonly IConfiguration _configuration;
        private readonly IMailService _emailService;
        public VeterinairesController(
           IVetRepo VetRepo,
           UserManager<AppUser> userManager,
           RoleManager<ApplicationRole> roleManager,
           AppDbContext context,
           IConfiguration configuration,
           IMailService mailService,
            ILogger<VeterinairesController> logger
       )
        {
            _vetRepo = VetRepo;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
            _configuration = configuration;
            _emailService = mailService;
            _logger = logger;
        }
        //vet list
        [HttpGet]
        [Route("get-all-veterinaires")]
        public async Task<IActionResult> GetAllVeterinaire()
        {
            var veterinaires= await _vetRepo.GetVeterinaires();
            return Ok(veterinaires);
        }
        //search vet
        [HttpGet]
        [Route("get-vet-by-id/{id}")]
        public async Task<IActionResult> GetVetById(Guid id)
        {
            var vet= await _vetRepo.GetVeterinaireById(id);
            if (vet == null)
                return BadRequest(new { message = "Veterinaire with this Id not found!" });
            return Ok(vet);
        }
        [HttpGet]
        [Route("get-vet-by-username/{username}")]
        public async Task<IActionResult> GetVetByUsername(string username)
        {
            var vet=await _vetRepo.GetVeterinaireByUsername(username);
            if(vet == null)
                return BadRequest(new {message ="Veterinaire with this username not found!"});
            return Ok(vet); 
        }
        //update

        [HttpPut]
        [Route("update-veterinaire/{id}")]
        public async Task<IActionResult> UpdateVeterinaire(Guid id, [FromBody] UpdateVetDto updatedVet)
        {
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if (appUser == null)
                return NotFound(new { message = "User not found" });

            string? oldRole = appUser.Role;


            if (!string.IsNullOrEmpty(updatedVet.Role))
            {
                var roleUpdated = await ReplaceRoleAsync(appUser, updatedVet.Role);
                if (!roleUpdated)
                    return BadRequest(new { message = "Failed to update role" });

                appUser.Role = updatedVet.Role;

                // Remove from old role table
                switch (oldRole?.ToLower())
                {
                    case "Client":
                        var oldClient = await _context.clients.FirstOrDefaultAsync(c => c.AppUserId == appUser.Id);
                        if (oldClient != null)
                            _context.clients.Remove(oldClient);
                        break;

                    case "Veterinaire":
                        var oldVet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUserId == appUser.Id);
                        if (oldVet != null)
                            _context.veterinaires.Remove(oldVet);
                        break;
                    case "Admin":
                        var oldAdmin = await _context.admins.FirstOrDefaultAsync(v => v.AppUserId == appUser.Id);
                        if (oldAdmin != null)
                            _context.admins.Remove(oldAdmin);
                        break;

                }

                // Add to new role table
                switch (updatedVet.Role.ToLower())
                {
                    case "Veterinaire":
                        var existingVet = await _context.veterinaires.FirstOrDefaultAsync(v => v.AppUserId == appUser.Id);
                        if (existingVet == null)
                        {
                            var vet = new Veterinaire
                            {
                                AppUserId = appUser.Id,
                            };
                            await _context.veterinaires.AddAsync(vet);
                        }
                        break;

                    case "Client":
                        var existingClient = await _context.clients.FirstOrDefaultAsync(c => c.AppUserId == appUser.Id);
                        if (existingClient == null)
                        {
                            var client = new Client
                            {
                                AppUserId = appUser.Id,
                            };
                            await _context.clients.AddAsync(client);
                        }
                        break;

                    case "Admin":
                        var existingAdmin = await _context.admins.FirstOrDefaultAsync(c => c.AppUserId == appUser.Id);
                        if (existingAdmin == null)
                        {
                            var admin = new Admin
                            {
                                AppUserId = appUser.Id,
                            };
                            await _context.admins.AddAsync(admin);
                        }
                        break;
                    default:
                        break;
                }
                await _context.SaveChangesAsync();

            }
            if (!string.IsNullOrEmpty(updatedVet.Password))
            {
                var removePassResult = await _userManager.RemovePasswordAsync(appUser);
                if (!removePassResult.Succeeded)
                    return BadRequest(new { message = "Failed to remove old password", errors = removePassResult.Errors });

                var addPassResult = await _userManager.AddPasswordAsync(appUser, updatedVet.Password);
                if (!addPassResult.Succeeded)
                    return BadRequest(new { message = "Failed to set new password", errors = addPassResult.Errors });
            }
            await _vetRepo.UpdateVeterinaire(id, updatedVet);


            return Ok(new { message = "Veterinaire updated successfully" });
        }
        private async Task<bool> ReplaceRoleAsync(AppUser user, string newRole)
        {
            var role = await _roleManager.FindByNameAsync(newRole);
            if (role == null)
            {
                return false;
            }
            var currentUserRoles = await _context.Set<IdentityUserRole<Guid>>()
                                                  .Where(ur => ur.UserId == user.Id)
                                                  .ToListAsync();

            _context.Set<IdentityUserRole<Guid>>().RemoveRange(currentUserRoles);

            var newUserRole = new IdentityUserRole<Guid> { UserId = user.Id, RoleId = role.Id };
            await _context.Set<IdentityUserRole<Guid>>().AddAsync(newUserRole);

            await _context.SaveChangesAsync();
            return true;
        }
        //delete vet
        [HttpDelete]
        [Route("delete-veterinaire")]
        public async Task<IActionResult> DeleteVet(Guid id)
        {
            var vet = await _context.veterinaires.FirstOrDefaultAsync(vet => vet.AppUserId == id);
            if (vet == null)
                return BadRequest("Veterinaire with this id not found");
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if(appUser !=null)
            {
                var result = await _userManager.DeleteAsync(appUser);
                if (!result.Succeeded)
                    return BadRequest(new { message = "Failed to delete user from Identity" });
            }
            await _vetRepo.DeleteVeterinaire(id);
            return Ok(new { message = "Veterinaire deleted successfully" });
        }
        //add vet
        [HttpPost]
        [Route("add-veterinaire")]
        public async Task<IActionResult> AddVeterinaire([FromBody] AddVetDto addedVet)
        {
            var vetEmailExists = await _userManager.FindByEmailAsync(addedVet.Email);

            if (vetEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "vet email already exists!"
                });
            }

            var vetNameExists = await _userManager.FindByNameAsync(addedVet.Username);
            if (vetNameExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "vet name already exists!"
                });
            }
            AppUser user = new()
            {
                Id = Guid.NewGuid(),
                SecurityStamp = Guid.NewGuid().ToString(),
                Role = ApplicationRole.Veterinaire,
                Email = addedVet.Email,
                UserName = addedVet.Username,
                EmailConfirmed = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,

                TwoFactorEnabled = true,
                TwoFactorExpiration = DateTime.UtcNow.AddMinutes(5),
                PhoneNumber = "",
                LockoutEnd = null,
                LockoutEnabled = true,
                AccessFailedCount = 0,

                CodeConfirmationLogin = "",
                Enabled = true,
                Expired = false,
                FirstName = "",
                LastName = "",
                Locked = false,
                EmailValidated = false,
                Gender = "",
                BirthDate = DateTime.UtcNow,
                Address = "",
                ZipCode = "",
                PhoneValidated = false,
                PhoneValidationCode = "",
                EmailValidationCode = "",

            };
            var result = await _userManager.CreateAsync(user, addedVet.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user, " + errors
                });
            }

            Veterinaire veterinaire = new Veterinaire()
            {
                AppUserId = user.Id
            };
            await _vetRepo.AddVeterinaire(veterinaire);

            if (!await _roleManager.RoleExistsAsync(ApplicationRole.Veterinaire))
            {
                await _roleManager.CreateAsync(new ApplicationRole(ApplicationRole.Veterinaire));
            }

            if (await _roleManager.RoleExistsAsync(ApplicationRole.Veterinaire))
            {
                var role = await _roleManager.FindByNameAsync(ApplicationRole.Veterinaire);
                var applicationUserRole = new IdentityUserRole<Guid>
                {
                    UserId = user.Id,
                    RoleId = role.Id
                };

                await _context.UserRoles.AddAsync(applicationUserRole);
                await _context.SaveChangesAsync();
            }
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            if (string.IsNullOrEmpty(token))
            {
                Console.WriteLine("Failed to generate a confirmation token to veterinaire.");
                return BadRequest("Token generation failed.");
            }

            user.TwoFactorCode = token;
            await _context.SaveChangesAsync();

            string confirmationUrl = $"{_configuration["ApiUrls:ConfirmVetEmailUrl"]}/?email={user.Email}&code={token}";

            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
                { "Code", token },
                { "ConfirmationUrl", confirmationUrl },
            };

            MailDataModel mailData = new()
            {
                TemplateName = "VetRegisterEmailTemplate.html",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "Veterinaire Registration: Email Confirmation",
                Variables = Variables
            };
            try
            {
                _emailService.SendHTMLTemplateMail(mailData);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error sending email: " + ex.Message, ex);
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error sending email",
                    Message = ex.ToString()
                });
            }

            return Ok(new ApiResponse { Status = "Success", Message = "Veterinaire successfully created, he must check his email for confirmation!" });

        }
    }
}
