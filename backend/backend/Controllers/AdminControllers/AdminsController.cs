using backend.Dtos.AdminDtos.AdminAuthDto;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Identity;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Mail;
using backend.Dtos.AdminDtos;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminsController : ControllerBase
    {
        public readonly IAdminRepo _adminRepo;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly AppDbContext _context;
        private readonly ILogger _logger;
        private readonly IConfiguration _configuration;
        private readonly IMailService _emailService;

        public AdminsController(
            IAdminRepo adminRepo,
            UserManager<AppUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            AppDbContext context,
            IConfiguration configuration,
            IMailService mailService
        )
        {
            _adminRepo = adminRepo;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
            _configuration = configuration;
            _emailService = mailService;
        }
        [HttpGet("test-auth")]
        [Authorize]
        public IActionResult TestAuth()
        {
            return Ok("Auth works!");
        }

        //AdminList
        [HttpGet]
        [Route("get-all-admins")]
        [Authorize(Roles = "Admin")]
        public IActionResult GetAllAdmins()
        {
            Console.WriteLine("GET /api/admins/get-all-admins was hit.");

            var admins = _adminRepo.GetAdmins();
            return Ok(admins);
        }

        //SearchAdmin
        [HttpGet]
        [Route("get-admin-by-id/{id}")]
        public IActionResult GetAdminById(Guid id)
        {
            var admin = _adminRepo.GetAdminById(id);

            if (admin == null || admin.Role != "Admin")
                return BadRequest(new { message = "Admin with this Id not found" });
            return Ok(admin);
        }

        [HttpGet]
        [Route("get-admin-by-username/{username}")]
        public IActionResult GetAdminByUsername(string username)
        {
            var admin = _adminRepo.GetAdminByUsername(username);

            if (admin == null || admin.Role != "Admin")
                return BadRequest(new { message = "Admin with this username not found" });
            return Ok(admin);
        }

        //update

        [HttpPut]
        [Route("update-Admin/{id}")]
        public async Task<IActionResult> UpdateAdmin(Guid id, [FromBody] UpdateAdminDto updatedAdmin)
        {
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if (appUser == null)
                return NotFound(new { message = "User not found" });

            var adminEmailExists = await _userManager.FindByEmailAsync(updatedAdmin.Username);

            if (!string.IsNullOrEmpty(updatedAdmin.Role))
            {
                var roleUpdated = await ReplaceRoleAsync(appUser, updatedAdmin.Role);
                if (!roleUpdated)
                    return BadRequest(new { message = "Failed to update role" });
            }
            appUser.Role = updatedAdmin.Role;

            if (!string.IsNullOrEmpty(updatedAdmin.Password))
            {
                var removePassResult = await _userManager.RemovePasswordAsync(appUser);
                if (!removePassResult.Succeeded)
                    return BadRequest(new { message = "Failed to remove old password", errors = removePassResult.Errors });

                var addPassResult = await _userManager.AddPasswordAsync(appUser, updatedAdmin.Password);
                if (!addPassResult.Succeeded)
                    return BadRequest(new { message = "Failed to set new password", errors = addPassResult.Errors });
            }
            _adminRepo.UpdateAdmin(id, updatedAdmin);

            return Ok(new { message = "Admin updated successfully" });
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

        // DeleteAdmin
        [HttpDelete]
        [Route("delete-admin/{id}")]
        public async Task<IActionResult> DeleteAdmin(Guid id)
        {
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if (appUser != null)
            {
                var result = await _userManager.DeleteAsync(appUser);
                if (!result.Succeeded)
                    return BadRequest(new { message = "Failed to delete user from Identity" });
            }

            _adminRepo.DeleteAdmin(id);

            return Ok(new { message = "User deleted successfully" });
        }

        //AddAdmin
        [HttpPost]
        [Route("add-admin")]

        public async Task<IActionResult> AddAdminAsync(AddAdminDto addedAdmin)
        {
            var adminEmailExists = await _userManager.FindByEmailAsync(addedAdmin.Email);
            if (adminEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "admin email already exists!"
                });
            }

            var adminNameExists = await _userManager.FindByNameAsync(addedAdmin.Username);
            if (adminNameExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "admin name already exists!"
                });
            }

            AppUser user = new()
            {
                Id = Guid.NewGuid(),
                SecurityStamp = Guid.NewGuid().ToString(),
                Role = ApplicationRole.Admin,
                Email = addedAdmin.Email,
                UserName = addedAdmin.Username,
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
            var result = await _userManager.CreateAsync(user, addedAdmin.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user, " + errors
                });
            }

            Admin admin = new Admin()
            {
                AppUserId = user.Id
            };
            _adminRepo.AddAdmin(admin);

            if (!await _roleManager.RoleExistsAsync(ApplicationRole.Admin))
            {
                await _roleManager.CreateAsync(new ApplicationRole(ApplicationRole.Admin));
            }

            if (await _roleManager.RoleExistsAsync(ApplicationRole.Admin))
            {
                var role = await _roleManager.FindByNameAsync(ApplicationRole.Admin);
                var applicationUserRole = new IdentityUserRole<Guid>
                {
                    UserId = user.Id,
                    RoleId = role.Id
                };

                _context.UserRoles.AddAsync(applicationUserRole);
                await _context.SaveChangesAsync();
            }
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            if (string.IsNullOrEmpty(token))
            {
                Console.WriteLine("Failed to generate a confirmation token to admin.");
                return BadRequest("Token generation failed.");
            }

            user.TwoFactorCode = token;
            await _context.SaveChangesAsync();

            string confirmationUrl = $"{_configuration["ApiUrls:ConfirmAdminEmailUrl"]}/?email={user.Email}&code={token}";

            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
                { "Code", token },
                { "ConfirmationUrl", confirmationUrl },
            };

            MailDataModel mailData = new()
            {
                TemplateName = "AdminRegisterEmailTemplate.html",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "Admin Registration: Email Confirmation",
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
            return Ok(new ApiResponse { Status = "Success", Message = "Admin successfully created, he must check his email for confirmation!" });

        }
    }
}
