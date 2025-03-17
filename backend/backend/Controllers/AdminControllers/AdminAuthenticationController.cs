using Azure;
using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo;
using MailKit;
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
        private readonly Mail.IMailService _emailService;
        private readonly IOptions<DataProtectionTokenProviderOptions> _tokenOptions;
        private readonly AppDbContext _context;

        public AdminAuthenticationController(
            IConfiguration configuration,
            IAdminRepo repository,
            UserManager<AppUser> userManager,
            RoleManager<ApplicationRole> roleManager,

            ILogger<AdminAuthenticationController> logger,
            Mail.IMailService emailService,
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
        public async Task<IActionResult> Register([FromBody] AdminRegisterDto adminRegister)
        {
            var userEmailExists = await _userManager.FindByEmailAsync(adminRegister.Email);
            var userNameExists = await _userManager.FindByNameAsync(adminRegister.Username);


            if (userEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User email already exists"
                });
            }
            
            if ( userNameExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message="User name already exists"
                });
            }

            AppUser user = new()
            {
                Id = Guid.NewGuid(),
                SecurityStamp = Guid.NewGuid().ToString(),
                Email = adminRegister.Email,
                UserName = adminRegister.Username,
                CreatedAt = DateTime.UtcNow,  
                UpdatedAt = DateTime.UtcNow
            };
            
            var result =await _userManager.CreateAsync(user, adminRegister.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user , "+ errors
                });
            }
            if (!await _roleManager.RoleExistsAsync(UserRole.Admin))
            {
                var role = new ApplicationRole(UserRole.Admin);
                await _roleManager.CreateAsync(role);
            }

            if (!await _roleManager.RoleExistsAsync(UserRole.Client))
            {
                var role = new ApplicationRole(UserRole.Client);
                await _roleManager.CreateAsync(role);
            }

            if (!await _roleManager.RoleExistsAsync(UserRole.Veterinaire))
            {
                var role = new ApplicationRole(UserRole.Veterinaire);
                await _roleManager.CreateAsync(role);
            }
            

            await _userManager.AddToRoleAsync(user, UserRole.Admin);

            _repository.Register(user);

            string code = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            user.TwoFactorCode = code;
            await _context.SaveChangesAsync();

            string encodedCode = WebUtility.UrlEncode(code);
            string Url = $"{_configuration["AdminBaseUrl"]}/confirm-admin-email?email={user.Email}&code={encodedCode}";


            var Variables = new Dictionary<string, string>();
            Variables["Url"] = Url;
            Variables["BaseUrl"] = _configuration["BaseUrl"];
            Variables["ApiBaseUrl"] = _configuration["ApiBaseUrl"];

            HTMLTemplateMailData mailData = new HTMLTemplateMailData()
            {
                TemplateName = "AdminEmailConfirmation",
                EmailSubject = "Inscription Admin : Confirmation d\'email",
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
            return Ok(new ApiResponse { Status = "Success", Message = "User successfully created!" });

        }



        /*[HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] AdminLoginDto adminLogin)
        {
            var user = await _userManager.FindByEmailAsync(adminLogin.Email);
           if (user != null && await _userManager.CheckPasswordAsync(user,adminLogin.Password) && user.EmailConfirmed)
            {
                var UserRoles = await _userManager.GetRolesAsync(user);
                var TwoFactorTokenAsyncToken = await _userManager.GenerateTwoFactorTokenAsync(user, "Email");
                var Variables = new Dictionary<string, string>();
                Variables["UserName"] = user.UserName;
                Variables["AuthentificationCode"] = TwoFactorTokenAsyncToken;
                Variables["TokenLifeSpan"] = _configuration.GetSection("2FA:TokenLifeSpan").Get<int>().ToString();
                Variables["BaseUrl"] = _configuration["BaseUrl"];
                Variables["ApiBaseUrl"] = _configuration["ApiBaseUrl"];
                var admin = _context.AppUsers.FirstOrDefault(x => x.Id == user.Id);

                if (admin == null)
                {
                    _logger.LogError("Admin not found.");
                    return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
                }
                HTMLTemplateMailData mailData = new HTMLTemplateMailData()
                {
                    TemplateName = "AdminEmailAuthenticationCode",
                    EmailSubject = "Authentication code",

                    EmailToName = user.UserName,
                    EmailToId = user.Email,
                    Variables = Variables
                };

                try
                {
                    await _emailService.SendHTMLTemplateMail(mailData);
                }
                catch (Exception ex)
                {
                    _logger.LogError("Error send email" + ex.Message, ex);
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error sending email",
                        Message = ex.ToString()
                    });



                }
                user.TwoFactorCode = TwoFactorTokenAsyncToken;
                user.TwoFactorExpiration = DateTime.UtcNow.AddMinutes(10);


                await _context.SaveChangesAsync();
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Success",
                    Message = " your authentication code!"
                });


            }

            else
            {
                _logger.LogWarning("User " + adminLogin.Email + " login fail");
                return Unauthorized();
            }

        }


        [HttpPost("2fa-verify")]
        public async Task<IActionResult> Verify2FA([FromBody] TwoFactorDto twoFactorDto)
        {
            var user = await _userManager.FindByIdAsync(twoFactorDto.UserId.ToString());
            if (user == null)
                return Unauthorized(new { message = "Invalid user!" });

            var isValidCode = await _userManager.VerifyTwoFactorTokenAsync(user, "Email", twoFactorDto.Code);
            if (!isValidCode)
                return Unauthorized(new { message = "Invalid 2FA code!" });

            var token = GenerateJwtToken(user);
            return Ok(new { message = "2FA verification successful!", token });
        }


        [HttpPut("reset-password/{id}")]
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
