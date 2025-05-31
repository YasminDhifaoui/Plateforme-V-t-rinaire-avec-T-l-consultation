using backend.Controllers.AdminControllers;
using backend.Data;
using backend.Dtos.VetDtos.VetAuthDtos;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo;
using backend.Repo.AdminRepo.VetRepo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace backend.Controllers.VetControllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VetAuthentificationController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IVetRepo _repository;
        private readonly UserManager<AppUser> _userManager;
        private readonly RoleManager<ApplicationRole> _roleManager;


        private readonly ILogger _logger;
        private readonly IMailService _emailService;
        private readonly IOptions<DataProtectionTokenProviderOptions> _tokenOptions;
        private readonly AppDbContext _context;

        public VetAuthentificationController(
          IConfiguration configuration,
          IVetRepo repository,
          UserManager<AppUser> userManager,
          RoleManager<ApplicationRole> roleManager,

          ILogger<VetAuthentificationController> logger,
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
        public async Task<IActionResult> RegisterVet([FromBody] VetRegisterDto vetRegister)
        {
            var userEmailExists = await _userManager.FindByEmailAsync(vetRegister.Email);
            if (userEmailExists != null)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "User email already exists!"
                });
            }

            var userNameExists = await _userManager.FindByNameAsync(vetRegister.Username);
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
                Role = ApplicationRole.Veterinaire,
                Email = vetRegister.Email,
                UserName = vetRegister.Username,
                EmailConfirmed = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,

                TwoFactorEnabled = true,
                TwoFactorExpiration = DateTime.UtcNow.AddMinutes(5),
                PhoneNumber = "00000000",
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

            var result = await _userManager.CreateAsync(user, vetRegister.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Failed to create user, " + errors
                });
            }

            Veterinaire veterinaire = new()
            {
                AppUserId = user.Id
            };


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
                    RoleId = role!.Id
                };

                await _context.UserRoles.AddAsync(applicationUserRole);
                await _context.SaveChangesAsync();
            }

            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            if (string.IsNullOrEmpty(token))
            {
                Console.WriteLine("Failed to generate a confirmation token.");
                return BadRequest(new ApiResponse
                {
                    Status = "Error",
                    Message = "Token generation failed."
                });
            }

            user.TwoFactorCode = token;
            await _context.SaveChangesAsync();

            //string confirmationUrl = $"{_configuration["ApiUrls:ConfirmVetEmailUrl"]}/?email={user.Email}&code={token}";

            var Variables = new Dictionary<string, string>
            {
                { "UserName", user.UserName },
                { "Code", token },
                //{ "ConfirmationUrl", confirmationUrl },
            };

            MailDataModel mailData = new()
            {
                TemplateName = "VetRegisterEmailTemplate.html",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "Veterinaire Registration: Email Confirmation",
                Variables = Variables
            };
            await _repository.AddVeterinaire(veterinaire);

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
        [Route("confirm-veterinaire-email")]
        public async Task<IActionResult> confirmVetEmail([FromQuery] string email, [FromQuery] string code)
        {
            var EmailCodeModel = new VetConfirmEmailDto { Email =  email ,Code = code};
            var user = await _userManager.FindByEmailAsync(EmailCodeModel.Email);
            if (user == null)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error finding user",
                    Message = "User with email do not exist"
                });

            var veterinaire = _context.veterinaires.FirstOrDefault(x => x.AppUserId == user.Id);
            if (veterinaire == null)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error finding veterinaire",
                    Message = "veterinaire not found"
                });
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
            var result = await _userManager.ConfirmEmailAsync(user, EmailCodeModel.Code);
            if (!result.Succeeded)
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = "Invalid confirmation code"
                });
            user.EmailConfirmed = true;
            await _context.SaveChangesAsync();

            //string LoginUrl = $"{_configuration["ApiUrls:VetLoginUrl"]}";

            var Variables = new Dictionary<string, string>
             {
                 { "UserName", user.UserName },
                // {"LoginUrl" , LoginUrl}
             };

            MailDataModel mailData = new()
            {
                TemplateName = "VetConfirmEmailTemplate.html",
                EmailToName = user.UserName,
                EmailToId = user.Email,
                EmailSubject = "Veterinaire Email Confirmation",
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
        public async Task<IActionResult> Login([FromBody] VetLoginDto model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            // Check if user exists
            if (user == null)
            {
                return NotFound(new ApiResponse
                {
                    Status = "Error",
                    Message = "User not found with the provided email."
                });
            }
            // Check if email is confirmed
            if (!user.EmailConfirmed)
            {
                return BadRequest(new ApiResponse
                {
                    Status = "Error",
                    Message = "Email not confirmed. Please check your inbox."
                });
            }
            // Check if password is correct
            var isPasswordCorrect = await _userManager.CheckPasswordAsync(user, model.Password);
            if (!isPasswordCorrect)
            {
                return BadRequest(new ApiResponse
                {
                    Status = "Error",
                    Message = "Incorrect password."
                });
            }
            if (user != null && await _userManager.CheckPasswordAsync(user, model.Password) && user.EmailConfirmed)
            {
                var UserRoles = await _userManager.GetRolesAsync(user);
                var TwoFactorTokenAsyncToken = await _userManager.GenerateTwoFactorTokenAsync(user, "Email");
                var Variables = new Dictionary<string, string>();
                Variables["UserName"] = user.UserName;
                Variables["AuthentificationCode"] = TwoFactorTokenAsyncToken;
                Variables["TokenLifeSpan"] = _configuration.GetSection("2FA:TokenLifeSpan").Get<int>().ToString();
                //Variables["ConfirmLoginCode"] = _configuration["ApiUrls:VetConfirmLoginCode"]!;

                var veterinaire = _context.veterinaires.FirstOrDefault(x => x.AppUserId == user.Id);

                if (veterinaire == null)
                {
                    _logger.LogError("Veterinaire not found.");
                    return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Veterinaire not found." });
                }
                MailDataModel mailData = new MailDataModel()
                {
                    TemplateName = "VetEmailAuthentificationCode.html",
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
        public async Task<IActionResult> Verify2FACode([FromBody] VetVerifyLoginDto model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user != null)
            {
                var veterinaire = _context.veterinaires.FirstOrDefault(x => x.AppUserId == user.Id);

                if (veterinaire == null)
                {
                    _logger.LogError("Veterinaire not found.");
                    return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Veterinaire not found." });
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
                         new Claim(ClaimTypes.Role, "Veterinaire"),
                         new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                         new Claim(JwtRegisteredClaimNames.Sub, user.UserName),
                         new Claim(JwtRegisteredClaimNames.Aud, _configuration["JWT:ValidAudience"]!),
                         new Claim(JwtRegisteredClaimNames.Iss, _configuration["JWT:ValidIssuer"]!),
                         new Claim("Id", user.Id.ToString())
                     };

                    var token_res = GetToken(authClaims);

                    string[] roles = { "Veterinaire" };
                    return Ok(new
                    {
                        token = new JwtSecurityTokenHandler().WriteToken(token_res),
                        data = new
                        {
                            expiration = token_res.ValidTo,
                            vetId = user.Id.ToString(),
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

        private string GenerateRandomNumericOtp(int length)
        {
            using (var rng = new RNGCryptoServiceProvider())
            {
                var bytes = new byte[length];
                rng.GetBytes(bytes);
                var otp = new StringBuilder();
                foreach (var b in bytes)
                {
                    otp.Append(b % 10); // Get a single digit (0-9)
                }
                return otp.ToString();
            }
        }


        [HttpPost]
        [Route("forgot-password")]
        public async Task<IActionResult> ForgetPasswordAsync([FromBody] VetForgetPasswordDto model)
        {
            if (string.IsNullOrEmpty(model.Email))
                return NotFound();
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)

                return StatusCode(StatusCodes.Status500InternalServerError, new Dtos.VetDtos.VetAuthDtos.ApiResponse
                {
                    Status = "Error",
                    Message = "No user associated with this email"
                });
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
            var veterinaire = _context.veterinaires.FirstOrDefault(x => x.AppUserId == user.Id);

            if (veterinaire == null)
            {
                _logger.LogError("Veterinaire not found.");
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Veterinaire not found." });
            }
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            byte[] encodedToken = Encoding.UTF8.GetBytes(token);
            var resetToken = WebEncoders.Base64UrlEncode(encodedToken);
            user.TokenCreationTime = DateTime.UtcNow;

            string otpCode = GenerateRandomNumericOtp(6);

            // Store both tokens and set OTP expiry on the user object
            user.OtpCode = otpCode;
            user.OtpExpiryTime = DateTime.UtcNow.AddMinutes(5); // OTP valid for 5 minutes (adjust as needed)
            user.IsOtpUsed = false;
            user.InternalResetToken = token; // *** THIS IS THE CRUCIAL LINE THAT WAS MISSING OR MISPLACED ***



            await _userManager.UpdateAsync(user);


            //string Url = $"{_configuration["VetBaseUrl"]}/reset-password?email={model.Email}&token={resetToken}";

            var Variables = new Dictionary<string, string>();
            Variables["UserName"] = user.UserName;
            //Variables["ResetPasswordUrl"] = Url;
            Variables["Token"] = resetToken;
            Variables["OtpCode"] = otpCode; // Send the short OTP code to the email template


            MailDataModel mailData = new MailDataModel()
            {
                TemplateName = "VetEmailResetPassword.html",
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
        [Route("verify-otp-code")]
        public async Task<IActionResult> VerifyOtpCode([FromBody] VetVerifyOtpCodeDto model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new ApiResponse { Status = "Error", Message = "Invalid input." });
            }

            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
            {
                // Generic error for security, don't reveal if user exists
                return BadRequest(new ApiResponse { Status = "Error", Message = "Invalid email or verification code." });
            }

            // Validate OTP and expiry conditions
            if (string.IsNullOrEmpty(user.OtpCode) || user.OtpCode != model.OtpCode ||
                user.OtpExpiryTime == null || user.OtpExpiryTime < DateTime.UtcNow || user.IsOtpUsed)
            {
                _logger.LogWarning($"Invalid, expired, or used OTP verification attempt for user: {model.Email}. Code provided: {model.OtpCode}");
                return BadRequest(new ApiResponse { Status = "Error", Message = "Invalid or expired verification code. " });
            }

            // OTP is valid but NOT invalidated here, as user still needs to provide new password.
            // This endpoint is for UI to know if they can proceed to the next step.
            return Ok(new ApiResponse { Status = "Success", Message = "Verification code is valid. You can now reset your password." });
        }


        [HttpPost]
        [Route("reset-password")]
        public async Task<IActionResult> ResetPasswordAsync([FromBody] VetResetPasswordDto model)
        {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null)
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse
                {
                    Status = "Error",
                    Message = "No user associated with email"
                });
            var veterinaire = _context.veterinaires.FirstOrDefault(x => x.AppUserId == user.Id);

            if (veterinaire == null)
            {
                _logger.LogError("Veterinaire not found.");
                return StatusCode(StatusCodes.Status404NotFound, new ApiResponse { Status = "Error", Message = "Veterinaire not found." });
            }
            if (model.NewPassword != model.ConfirmPassword)
                return StatusCode(StatusCodes.Status400BadRequest, new ApiResponse
                {
                    Status = "Error",
                    Message = "Password doesn't match its confirmation"
                });
            if (user.IsOtpUsed || string.IsNullOrEmpty(user.InternalResetToken))
            {
                _logger.LogWarning($"Attempt to reset password for user {model.Email} with already used OTP or missing internal token. IsOtpUsed: {user.IsOtpUsed}, InternalResetToken is null/empty: {string.IsNullOrEmpty(user.InternalResetToken)}");
                return StatusCode(StatusCodes.Status403Forbidden, new ApiResponse
                {
                    Status = "Error",
                    Message = "Password reset link/session expired or already used. Please request a new password reset."
                });
            }
            // Perform the actual password reset using the stored internal token
            var result = await _userManager.ResetPasswordAsync(user, user.InternalResetToken, model.NewPassword);

            if (result.Succeeded)
            {
                // Invalidate the OTP and internal token after successful use
                user.IsOtpUsed = true;
                user.OtpCode = null; // Clear the OTP
                user.InternalResetToken = null; // Clear the internal token
                user.OtpExpiryTime = null; // Clear expiry time
                await _userManager.UpdateAsync(user); // Save these changes

                _logger.LogInformation($"Password successfully reset for user: {model.Email}");
                return Ok(new ApiResponse { Status = "Success", Message = "Password has been reset successfully!" });
            }
            else
            {
                _logger.LogError($"Failed to reset password for user {model.Email}: {string.Join(", ", result.Errors.Select(e => e.Description))}");
                return StatusCode(StatusCodes.Status500InternalServerError, new ApiResponse
                {
                    Status = "Error",
                    Message = $"Failed to reset password: {string.Join(", ", result.Errors.Select(e => e.Description))}"
                });
            }

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
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
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
