using Azure;
using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using MailKit;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminAuthenticationController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IAdminRepo _repository;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;


        private readonly ILogger _logger;
        private readonly IMailService _emailService;
        private readonly IOptions<DataProtectionTokenProviderOptions> _tokenOptions;
        private readonly AppDbContext _context;

        public AdminAuthenticationController(
            IConfiguration configuration,
            IAdminRepo repository,
            UserManager<AppUser> userManager,
            RoleManager<ApplicationRole> roleManager,

            ILogger<AdminAuthenticationController> logger,
            IMailService emailService,
            IOptions<DataProtectionTokenProviderOptions> tokenOptions,
            AppDbContext context
        )
        {
            _configuration = configuration;
            _repository = repository;
            _userManager = userManager;
            _roleManager = roleManager;
            _logger = logger;
            _emailService = emailService;
            _tokenOptions = tokenOptions;
            _context = context;
        }


        [HttpPost("register")]
        public async Task<IActionResult> RegisterAdmin([FromBody] AdminRegisterDto adminRegister)
        {
            var userEmailExists = await _userManager.FindByEmailAsync(adminRegister.Email);
            if (userEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User email already exists!"
                });
            }

            var userNameExists = await _userManager.FindByNameAsync(adminRegister.Username);
            if (userNameExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User name already exists!"
                });
            }

            AppUser user = new()
            {
                Id = Guid.NewGuid(),
                SecurityStamp = Guid.NewGuid().ToString(),
                Role = ApplicationRole.Admin,
                Email = adminRegister.Email,
                UserName = adminRegister.Username,
                EmailConfirmed = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,

                TwoFactorEnabled = true,
                TwoFactorExpiration = DateTime.UtcNow.AddMinutes(5),
                PhoneNumber = "00000000",
                LockoutEnd = null,
                LockoutEnabled = true,
                AccessFailedCount = 0

            };

            var result = await _userManager.CreateAsync(user, adminRegister.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user, " + errors
                });
            }
            var userCreated = await _userManager.FindByEmailAsync(adminRegister.Email);
            if (userCreated == null)
            {
                return BadRequest("User was not found after creation.");
            }

            Admin admin = new()
            {
                AdminId = user.Id

            };

            _repository.RegisterAdmin(admin);

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

            if (user == null || string.IsNullOrEmpty(user.Email))
            {
                return BadRequest("User not found or email is invalid.");
            }
            var tokenProvider = _userManager.Options.Tokens.EmailConfirmationTokenProvider;
            Console.WriteLine("Token Provider: " + tokenProvider);


            var savedUser = await _userManager.FindByEmailAsync(adminRegister.Email);
            
            var token = Guid.NewGuid().ToString();
//            var token = await _userManager.GenerateEmailConfirmationTokenAsync(savedUser);

            if (string.IsNullOrEmpty(token))
            {
                Console.WriteLine("Failed to generate a confirmation token.");
                return BadRequest("Token generation failed.");
            }


            user.TwoFactorCode = token;
            await _context.SaveChangesAsync();


            string confirmationUrl = $"{_configuration["ApiUrls:ConfirmAdminEmailUrl"]}/?email={user.Email}&code={token}";

            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
                { "ConfirmationUrl", confirmationUrl },
            };

            HTMLTemplateMailData mailData = new()
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

            return Ok(new ApiResponse { Status = "Success", Message = "User successfully created check your email for confirmation!" });
        }

        [HttpPost]
        [Route("confirm-admin-email")]
        public async Task<IActionResult> confirmAdminEmail([FromBody] AdminConfirmEmailDto EmailCodeModel )
        {
            var user = await _userManager.FindByEmailAsync(EmailCodeModel.Email);
            if (user == null)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error finding user",
                    Message = "User with email " + user.Email + " do not exist"
                });

            var admin = _context.admins.FirstOrDefault(x => x.AdminId == user.Id);
            if (admin == null)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error finding admin",
                    Message = "admin not found"
                });
            var result = await _userManager.ConfirmEmailAsync(user, EmailCodeModel.Code);
            if (!result.Succeeded)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Invalid confirmation code"
                });
            user.EmailConfirmed = true;
            await _context.SaveChangesAsync();
            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
            };

            HTMLTemplateMailData mailData = new()
            {
                TemplateName = "AdminConfirmEmailTemplate",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "Admin Email Confirmation",
                Variables = Variables
            };

            try
            {
                _emailService.SendHTMLTemplateMail(mailData);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error send email" + ex.Message, ex);
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error send email",
                    Message = ex.ToString()
                });
            }
            return Ok(new ApiResponse { Status = "Success", Message = "Email confirmed successfully!" });

        }




        /*[HttpPost]
        [Route("login")]
        public async Task<IActionResult> Login([FromBody] AdminLoginDto model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);

            if (user != null && await _userManager.CheckPasswordAsync(user, model.Password) && user.EmailConfirmed)
            {

                var UserRoles = await _userManager.GetRolesAsync(user);
                var TwoFactorTokenAsyncToken = await _userManager.GenerateTwoFactorTokenAsync(user, "Email");
                var Variables = new Dictionary<string, string>();
                Variables["UserName"] = user.UserName;
                Variables["AuthentificationCode"] = TwoFactorTokenAsyncToken;
                Variables["TokenLifeSpan"] = _configuration.GetSection("2FA:TokenLifeSpan").Get<int>().ToString();
                
                var admin = _context.admins.FirstOrDefault(x => x.AdminId == user.Id);

                if (admin == null)
                {
                    _logger.LogError("Admin not found.");
                    return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
                }
                HTMLTemplateMailData mailData = new HTMLTemplateMailData()
                {
                    TemplateName = "AdminEmailAuthenticationCode",
                    EmailSubject = "Code d\'authentification",
                    EmailToName = user.UserName,
                    EmailToId = user.Email,
                    Variables = Variables
                };

                try
                {
                    _emailService.SendHTMLTemplateMail(mailData);
                }
                catch (Exception ex)
                {
                    _logger.LogError("Error send email" + ex.Message, ex);
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error send email",
                        Message = ex.ToString()
                    });


                }

                user.CodeConfirmationLogin = TwoFactorTokenAsyncToken;
                user.TokenCreationTime = DateTime.Now.ToUniversalTime();

                await _context.SaveChangesAsync();
                return Ok(new ApiResponse { Status = "Success", Message = " your authentication code!" });


            }
            else
            {
                _logger.LogWarning("User " + model.Email + " login fail");
                return Unauthorized();
            }

        }*/




       /* [HttpPut("reset-password/{id}")]
        public async Task<IActionResult> ResetPassword(string id, [FromBody] ChangePasswordDto changePassword)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { message = "User not found" });

            var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, resetToken, changePassword.NewPassword);
            if (!result.Succeeded)
                return BadRequest(result.Errors);

            return Ok(new { message = "Password updated successfully!" });
        }

        private string GenerateJwtToken(AppUser user)
        {
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                _configuration["Jwt:Issuer"],
                _configuration["Jwt:Audience"],
                claims,
                expires: DateTime.UtcNow.AddHours(2),
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }*/
    }
}
