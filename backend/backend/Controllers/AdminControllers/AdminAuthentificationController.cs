using Azure;
using backend.Data;
using backend.Dtos;
using backend.Dtos.AdminDtos.AdminAuthDto;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.AspNetCore.Authorization;

namespace backend.Controllers.AdminControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminAuthentificationController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IAdminRepo _repository;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;


        private readonly ILogger<AdminAuthentificationController> _logger;
        private readonly IMailService _emailService;
        private readonly IOptions<DataProtectionTokenProviderOptions> _tokenOptions;
        private readonly AppDbContext _context;

        public AdminAuthentificationController(
            IConfiguration configuration,
            IAdminRepo repository,
            UserManager<AppUser> userManager,
            RoleManager<ApplicationRole> roleManager,

            ILogger<AdminAuthentificationController> logger,
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
                AccessFailedCount = 0,

                CodeConfirmationLogin= "",
                Enabled = true,
                Expired= false,
                FirstName = "",
                LastName="",
                Locked = false,
                EmailValidated = false,
                Gender = "",
                BirthDate = DateTime.UtcNow,
                Address ="",
                ZipCode="",
                PhoneValidated =false,
                PhoneValidationCode = "",
                EmailValidationCode="",

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

            Admin admin = new()
            {
                AppUserId = user.Id
            };

            _repository.AddAdmin(admin);

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
                    RoleId = role!.Id
                };

                await _context.UserRoles.AddAsync(applicationUserRole);
                await _context.SaveChangesAsync();
            }
            
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);            
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

            return Ok(new ApiResponse { Status = "Success", Message = "User successfully created check your email for confirmation!" });
        }

         [HttpPost]
        [Route("confirm-admin-email")]
        public async Task<IActionResult> confirmAdminEmail([FromQuery] string email, [FromQuery] string code)
        {
            var EmailCodeModel = new AdminConfirmEmailDto { Email = email, Code = code };
            var user = await _userManager.FindByEmailAsync(EmailCodeModel.Email);
             if (user == null)
                 return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                 {
                     Status = "Error finding user",
                     Message = "User with email do not exist"
                 });

             var admin = _context.admins.FirstOrDefault(x => x.AppUserId == user.Id);
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

            string LoginUrl = $"{_configuration["ApiUrls:AdminLoginUrl"]}";

            if (user.UserName == null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User name is null."
                });
            }
            if (user.Email == null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User email is null."
                });
            }
            var Variables = new Dictionary<string, string>
             {
                 { "UserName", user.UserName },
                 {"LoginUrl" , LoginUrl}
             };

             MailDataModel mailData = new()
             {
                 TemplateName = "AdminConfirmEmailTemplate.html",
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

         [HttpPost]
         [Route("login")]
         public async Task<IActionResult> Login([FromBody] AdminLoginDto model)
         {
             var user = await _userManager.FindByEmailAsync(model.Email);

             if (user != null && await _userManager.CheckPasswordAsync(user, model.Password) && user.EmailConfirmed)
             {
                var UserRoles = await _userManager.GetRolesAsync(user);
                var TwoFactorTokenAsyncToken = await _userManager.GenerateTwoFactorTokenAsync(user, "Email");
                if (user.UserName == null)
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error",
                        Message = "User name is null."
                    });
                }
                if (user.Email == null)
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error",
                        Message = "User email is null."
                    });
                }
                var Variables = new Dictionary<string, string>();
                Variables["UserName"] = user.UserName;
                Variables["AuthentificationCode"] = TwoFactorTokenAsyncToken;
                Variables["TokenLifeSpan"] = _configuration.GetSection("2FA:TokenLifeSpan").Get<int>().ToString();
                Variables["ConfirmLoginCode"] = _configuration["ApiUrls:AdminConfirmLoginCode"]!;
               
                var admin = _context.admins.FirstOrDefault(x => x.AppUserId == user.Id);

                 if (admin == null)
                 {
                     _logger.LogError("Admin not found.");
                     return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
                 }
                 MailDataModel mailData = new MailDataModel()
                 {
                     TemplateName = "AdminEmailAuthentificationCode.html",
                     EmailSubject = "Authentification code",
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
                 return Ok(new ApiResponse { Status = "Success", Message = " your authentication code, check your email to confirm your login!" });
             }
             else
             {
                return Ok(new ApiResponse { Status = "Login failed", Message = " Login failed !" });
             }

         }

         [HttpPost]
         [Route("verify-login-code")]
         public async Task<IActionResult> Verify2FACode([FromBody] AdminVerifyLoginDto model)
         {
             var user = await _userManager.FindByEmailAsync(model.Email);
             if (user != null)
             {
                 var admin = _context.admins.FirstOrDefault(x => x.AppUserId == user.Id);

                 if (admin == null)
                 {
                     _logger.LogError("Admin not found.");
                     return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
                 }
                if (user.UserName == null)
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error",
                        Message = "User name is null."
                    });
                }
                if (user.Email == null)
                {
                    return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                    {
                        Status = "Error",
                        Message = "User email is null."
                    });
                }
                var token = user.CodeConfirmationLogin;
                 var isTokenValid = await _userManager.VerifyTwoFactorTokenAsync(user, "Email", model.Code);
                 var isTokenNotExpired = IsTokenValidAsync(user.TokenCreationTime);

                 if (isTokenValid && isTokenNotExpired)
                 {
                     _logger.LogInformation("User " + model.Email + " successfully logged in");

                    //a list of claims: key-value pairs representing user data.
                    var authClaims = new List<Claim>
                     {
                         new Claim(ClaimTypes.Email, user.Email),
                         new Claim(ClaimTypes.Name, user.UserName),
                         new Claim(ClaimTypes.Role, "Admin"),
                         new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                         new Claim(JwtRegisteredClaimNames.Sub, user.UserName),
                         new Claim(JwtRegisteredClaimNames.Aud, _configuration["JWT:ValidAudience"]!),
                         new Claim(JwtRegisteredClaimNames.Iss, _configuration["JWT:ValidIssuer"]!),
                         new Claim("Id", user.Id.ToString())  
                     };

                     var token_res = GetToken(authClaims);

                     string[] roles = { "Admin" };
                     return Ok(new
                     {
                         token = new JwtSecurityTokenHandler().WriteToken(token_res),
                         data = new
                         {
                             expiration = token_res.ValidTo,
                             created = DateTime.Now,
                             email = user.Email,
                             username = user.UserName,
                             roles
                         }
                     });
                 }
                 else
                 {
                     _logger.LogError("Invalid or expired code.");
                     return StatusCode(StatusCodes.Status401Unauthorized, new ApiResponse
                     {
                         Status = "Error",
                         Message = "Invalid or expired code."
                     });
                 }
             }
             return StatusCode(StatusCodes.Status401Unauthorized, new ApiResponse { Status = "Error", Message = "login fail!" });

         }

        [HttpPost]
        [Route("forgot-password")]
        public async Task<IActionResult> ForgetPasswordAsync([FromBody] AdminForgetPasswordDto model)
        {
            if (string.IsNullOrEmpty(model.Email))
                return NotFound();
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)

                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "No user associated with this email"
                });
            var admin = _context.admins.FirstOrDefault(x => x.AppUserId == user.Id);

            if (admin == null)
            {
                _logger.LogError("Admin not found.");
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
            }
            if (user.UserName == null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User name is null."
                });
            }
            if (user.Email == null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User email is null."
                });
            }
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            byte[] encodedToken = Encoding.UTF8.GetBytes(token);
            var resetToken = WebEncoders.Base64UrlEncode(encodedToken);
            user.TokenCreationTime  = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);


            string Url = $"{_configuration["AdminBaseUrl"]}/reset-password?email={model.Email}&token={resetToken}";

            var Variables = new Dictionary<string, string>();
            Variables["UserName"] = user.UserName;
            Variables["ResetPasswordUrl"] = Url;
            Variables["Token"] = resetToken;

            MailDataModel mailData = new MailDataModel()
            {
                TemplateName = "AdminEmailResetPassword.html",
                EmailSubject = "Reset Password",
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
            return Ok(new ApiResponse { Status = "Success", Message = "Reset password URL has been sent to the email successfully!" });

        }
        [HttpPost]
        [Route("reset-password")]
        public async Task<IActionResult> ResetPasswordAsync([FromQuery] string email,[FromQuery] string token, [FromBody] AdminResetPasswordDto model)
        {


        var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse
                {
                    Status = "Error",
                    Message = "No user associated with email"
                });
            var admin = _context.admins.FirstOrDefault(x => x.AppUserId == user.Id);

            if (admin == null)
            {
                _logger.LogError("Admin not found.");
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Admin not found." });
            }
            if (model.NewPassword != model.ConfirmPassword)
                return StatusCode(StatusCodes.Status400BadRequest, new ApiResponse
                {
                    Status = "Error",
                    Message = "Password doesn't match its confirmation"
                });

            var isTokenNotExpired = IsTokenValidAsync(user.TokenCreationTime);
            if (!isTokenNotExpired)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new ApiResponse
                {
                    Status = "Error",
                    Message = "Expired reset token."
                });
            }

            var isTokenValid = await _userManager.VerifyUserTokenAsync(user, TokenOptions.DefaultProvider, UserManager<AppUser>.ResetPasswordTokenPurpose, token);
            if (isTokenValid)
                return StatusCode(StatusCodes.Status403Forbidden, new ApiResponse
                {
                    Status = "Error",
                    Message = "Token is incorrect."
                });

            var decodedToken = WebEncoders.Base64UrlDecode(token);
            string normalToken = Encoding.UTF8.GetString(decodedToken);

            var result = await _userManager.ResetPasswordAsync(user, normalToken, model.NewPassword);

            if (result.Succeeded)
                return Ok(new ApiResponse { Status = "Success", Message = "Password has been reset successfully!" });

            return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
            {
                Status = "Error",
                Message = "Something went wrong"
            });
        }
        private bool IsTokenValidAsync(DateTime? tokenCreationTime)
        {
            if (!tokenCreationTime.HasValue)
                return false;

            var lifespanMinutes = int.Parse(_configuration["2FA:TokenLifeSpan"]!);
            var expirationTime = tokenCreationTime.Value.AddMinutes(lifespanMinutes);

            return DateTime.UtcNow <= expirationTime;
        }


        private JwtSecurityToken GetToken(List<Claim> authClaims)
        {
            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JWT:SecretKey"]!));
            var credentials = new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256);
            var token = new JwtSecurityToken(
                issuer: _configuration["JWT:ValidIssuer"],
                audience: _configuration["JWT:ValidAudience"],
                expires: DateTime.Now.AddHours(Double.Parse(_configuration["JWT:ExpiresHours"]!)),
                claims: authClaims,
                signingCredentials: credentials
                );

            return token;
        }
        private string GenerateJwtToken(AppUser user)
          {
            if (string.IsNullOrEmpty(user.UserName))
            {
                throw new Exception("UserName must not be null.");
            }
            var claims = new[]
              {
                  new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                  new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName)
              };
            var jwtKey = _configuration["Jwt:Key"];
            if (string.IsNullOrEmpty(jwtKey))
            {
                throw new Exception("JWT key is missing from configuration.");
            }
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

              var token = new JwtSecurityToken(
                  _configuration["Jwt:Issuer"],
                  _configuration["Jwt:Audience"],
                  claims,
                  expires: DateTime.UtcNow.AddHours(2),
                  signingCredentials: creds);

              return new JwtSecurityTokenHandler().WriteToken(token);
          }
    }
}
