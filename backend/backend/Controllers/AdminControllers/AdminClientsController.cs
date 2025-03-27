using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Dtos.ClientDtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using backend.Repo.ClientsRepo;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Identity;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Mail;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminClientsController: ControllerBase
    {
        public readonly IClientRepo _clientRepo;
        public readonly IAdminRepo _adminRepo;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly AppDbContext _context;
        private readonly ILogger _logger;
        private readonly IConfiguration _configuration;
        private readonly IMailService _emailService;

        public AdminClientsController(
            IClientRepo ClientRepo,
            IAdminRepo adminRepo, 
            UserManager<AppUser> userManager, 
            RoleManager<ApplicationRole> roleManager,
            AppDbContext context,
            IConfiguration configuration,
            IMailService mailService
        )
        {
            _clientRepo = ClientRepo;
            _adminRepo = adminRepo;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
            _configuration = configuration;
            _emailService = mailService;
        }

        //ClientsList
        [HttpGet]
        [Route("GetAllClients")]
        public IActionResult GetAllClients()
        {
            var Clients = _clientRepo.GetClients();
            return Ok(Clients);
        }

        //SearchClient
        [HttpGet]
        [Route("GetClientById/{id}")]
        public IActionResult GetClientById(Guid id)
        {
            var client = _clientRepo.GetClientById(id);

            if (client == null || client.Role != "Client") 
                return BadRequest(new { message = "Client with this Id not found" });
            return Ok(client);
        }

        [HttpGet]
        [Route("GetClientByUsername/{username}")]
        public IActionResult GetClientByUsername(string username)
        {
            var client = _clientRepo.GetClientByUsername(username);

            if (client == null || client.Role != "Client")
                return BadRequest(new { message = "Client with this username not found" });
            return Ok(client);
        }

        // updateClient
        [HttpPut]
        [Route("updateClient/{id}")]
        public IActionResult UpdateUser(Guid id, [FromBody] UpdateClientDto updatedClient)
        {
            var client = _clientRepo.GetClientById(id);

            if (client == null) return NotFound();

            _clientRepo.UpdateClient(client.Id, updatedClient);

            return Ok(new { message = "Client updated" });
        }

        // DeleteClient
        [HttpDelete]
        [Route("deleteClient/{id}")]
        public IActionResult DeleteUser(Guid id)
        {
            var user = _clientRepo.GetClientById(id);
            if (user == null) return NotFound();

            _clientRepo.DeleteClient(id);
            return Ok(new { message = "User deleted" });
        }
        //AddClient
        [HttpPut]
        [Route("AddClient")]

        public async Task<IActionResult> AddClientAsync(AddClientDto addedClient)
        {
            var clientEmailExists = await _userManager.FindByEmailAsync(addedClient.Email);
            if (clientEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "client email already exists!"
                });
            }

            var clientNameExists = await _userManager.FindByNameAsync(addedClient.Username);
            if (clientNameExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "client name already exists!"
                });
            }

            AppUser user = new()
            {
                Id = Guid.NewGuid(),
                SecurityStamp = Guid.NewGuid().ToString(),
                Role = ApplicationRole.Client,
                Email = addedClient.Email,
                UserName = addedClient.Username,
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
            var result = await _userManager.CreateAsync(user, addedClient.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user, " + errors
                });
            }

            Client client = new Client()
            {
                AppUserId=user.Id
            };
            _clientRepo.AddClient(client);

            if (!await _roleManager.RoleExistsAsync(ApplicationRole.Client))
            {
                await _roleManager.CreateAsync(new ApplicationRole(ApplicationRole.Client));
            }

            if (await _roleManager.RoleExistsAsync(ApplicationRole.Client))
            {
                var role = await _roleManager.FindByNameAsync(ApplicationRole.Client);
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
                Console.WriteLine("Failed to generate a confirmation token to client.");
                return BadRequest("Token generation failed.");
            }

            user.TwoFactorCode = token;
            await _context.SaveChangesAsync();

            string confirmationUrl = $"{_configuration["ApiUrls:ConfirmClientEmailUrl"]}/?email={user.Email}&code={token}";

            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
                { "Code", token },
                { "ConfirmationUrl", confirmationUrl },
            };

            MailDataModel mailData = new()
            {
                TemplateName = "ClientRegisterEmailTemplate.html",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "client Registration: Email Confirmation",
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

            return Ok(new ApiResponse { Status = "Success", Message = "Client successfully created, he must check his email for confirmation!" });



        }
    }
}
