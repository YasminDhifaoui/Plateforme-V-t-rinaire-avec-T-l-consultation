﻿using backend.Dtos.AdminDtos.AdminAuthDto;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Identity;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Mail;
using backend.Dtos.AdminDtos.ClientDtos;
using backend.Repo.AdminRepo.ClientsRepo;

namespace backend.Controllers.AdminControllers
{
    [Route("api/admin/[controller]")]
    [ApiController]
    [Authorize(Policy = "Admin")]

    public class ClientsController: ControllerBase
    {
        public readonly IClientRepo _clientRepo;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;
        private readonly AppDbContext _context;
        private readonly ILogger<ClientsController> _logger;
        private readonly IConfiguration _configuration;
        private readonly IMailService _emailService;

        public ClientsController(
            IClientRepo ClientRepo,
            UserManager<AppUser> userManager, 
            RoleManager<ApplicationRole> roleManager,
            AppDbContext context,
            IConfiguration configuration,
            IMailService mailService,
            ILogger<ClientsController> logger

        )
        {
            _clientRepo = ClientRepo;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
            _configuration = configuration;
            _emailService = mailService;
            _logger = logger;
        }

        //ClientsList
        [HttpGet]
        [Route("get-all-clients")]
        public async Task<IActionResult>  GetAllClients()
        {
            var Clients =await _clientRepo.GetClientsAsync();
            return Ok(Clients);
        }

        //SearchClient
        [HttpGet]
        [Route("get-client-by-id/{id}")]
        public async Task<IActionResult> GetClientById(Guid id)
        {
            var client = await _clientRepo.GetClientByIdAsync(id);

            if (client == null || client.Role != "Client") 
                return BadRequest(new { message = "Client with this Id not found" });
            return Ok(client);
        }

        [HttpGet]
        [Route("get-client-by-username/{username}")]
        public async Task<IActionResult> GetClientByUsername(string username)
        {
            var client = await _clientRepo.GetClientByUsernameAsync(username);

            if (client == null || client.Role != "Client")
                return BadRequest(new { message = "Client with this username not found" });
            return Ok(client);
        }

        //update

        [HttpPut]
        [Route("update-client/{id}")]
        public async Task<IActionResult> UpdateClient(Guid id, [FromBody] UpdateClientDto updatedClient)
        {
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if (appUser == null)
                return NotFound(new { message = "User not found" });

            string? oldRole = appUser.Role;


            if (!string.IsNullOrEmpty(updatedClient.Role))
            {
                var roleUpdated = await ReplaceRoleAsync(appUser, updatedClient.Role);
                if (!roleUpdated)
                    return BadRequest(new { message = "Failed to update role" });

                appUser.Role = updatedClient.Role;
                await _context.SaveChangesAsync();

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
                switch (updatedClient.Role.ToLower())
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

            }

            if (!string.IsNullOrEmpty(updatedClient.Password))
            {
                var removePassResult = await _userManager.RemovePasswordAsync(appUser);
                if (!removePassResult.Succeeded)
                    return BadRequest(new { message = "Failed to remove old password", errors = removePassResult.Errors });

                var addPassResult = await _userManager.AddPasswordAsync(appUser, updatedClient.Password);
                if (!addPassResult.Succeeded)
                    return BadRequest(new { message = "Failed to set new password", errors = addPassResult.Errors });
            }
            await _clientRepo.UpdateClientAsync(id, updatedClient);


            return Ok(new { message = "Client updated successfully" });
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

            return true;
        }

        // DeleteClient
        [HttpDelete]
        [Route("delete-client/{id}")]
        public async Task<IActionResult> DeleteClient(Guid id)
        {
            var appUser = await _userManager.FindByIdAsync(id.ToString());
            if(appUser == null)
                return BadRequest(new { message = "User with this Id not found !" });
          
            var result = await _userManager.DeleteAsync(appUser);
            if (!result.Succeeded)
                return BadRequest(new { message = "Failed to delete user from Identity" });
            

            await _clientRepo.GetClientByIdAsync(id);

            return Ok(new { message = "User deleted successfully" });
        }

        //AddClient
        [HttpPost]
        [Route("add-client")]

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
            await _clientRepo.AddClientAsync(client);

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

                await _context.UserRoles.AddAsync(applicationUserRole);
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
