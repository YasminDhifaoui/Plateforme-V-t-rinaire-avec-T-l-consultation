using backend.Data;
using backend.Mail;
using backend.Models;
using backend.Repo.AdminRepo;
using backend.Repo.AdminRepo.AnimalRepo;
using backend.Repo.AdminRepo.ClientsRepo;
using backend.Repo.AdminRepo.ConsultationRepo;
using backend.Repo.AdminRepo.VetRepo;
using backend.Repo.ClientRepo.AnimalRepo;
using backend.Repo.ClientRepo.ConsultationRepo;
using backend.Repo.ClientRepo.RendezVousRepo;
using backend.Repo.Rendez_vousRepo;
using backend.Repo.VetRepo.AnimalRepo;
using backend.Repo.VetRepo.ConsultationRepo;
using backend.Repo.VetRepo.RendezVousRepo;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using backend.Repo.AdminRepo.VaccinationRepo;
using backend.Repo.ClientRepo.VaccinationRepo;
using backend.Repo.VetRepo.VaccinationRepo;
using backend.Repo.ClientRepo.ProfileRepo;
using backend.Repo.VetRepo.ProfileRepo;
using backend.Repo.AdminRepo.ProfileRepo;
using backend.Repo.ClientRepo.VetRepo;
using backend.Repo.VetRepo.ClientRepo;
using backend.Repo.AdminRepo.ProductsRepo;
using backend.Repo.VetRepo.ProductRepo;
using Microsoft.AspNetCore.SignalR;
using backend;
using Microsoft.AspNetCore.Http.Connections;

var builder = WebApplication.CreateBuilder(args);

var jwtSettings = builder.Configuration.GetSection("JWT");



builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ListenAnyIP(5000); // for HTTP
    serverOptions.ListenAnyIP(5001, listenOptions => {
        listenOptions.UseHttps();     // for HTTPS
    });
});

// Add services to the container.
builder.Services.AddCors(options => {
    options.AddPolicy("AllowAll", policy => {
        policy.WithOrigins("http://localhost", "https://localhost")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials()
              .SetIsOriginAllowed(_ => true); // Temporary override
    });
});

builder.Services.AddControllers();



// Swagger Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Your API", Version = "v1" });

    // Add JWT Bearer auth
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = @"JWT Authorization header using the Bearer scheme.  
                        Enter 'Bearer' [space] and then your token in the text input below.
                        Example: Bearer abcdef12345",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header,
            },
            new List<string>()
        }
    });
    c.SupportNonNullableReferenceTypes(); 

});



// Email SMTP Service
builder.Services.AddScoped<IMailService, MailService>();

// Add Admin Repositories
builder.Services.AddScoped<IAdminRepo, AdminRepo>();
builder.Services.AddScoped<IClientRepo, ClientRepo>();
builder.Services.AddScoped<IVetRepo, VetRepo>();
builder.Services.AddScoped<IAnimalRepo, AnimalRepo>();
builder.Services.AddScoped<IRendezVousRepo, RendezVousRepo>();
builder.Services.AddScoped<IConsultationRepo, consultationRepo>();
builder.Services.AddScoped<IVaccinationRepo, VaccinationRepo>();
builder.Services.AddScoped<IAdminProfileRepo, AdminProfileRepo>();
builder.Services.AddScoped<IProductRepository, ProductRepo>();



// add Client Repositories
builder.Services.AddScoped<IAnimalCRepo, AnimalCRepo>();
builder.Services.AddScoped<IRendezVousCRepo, RendezVousCRepo>();
builder.Services.AddScoped<IConsultationCRepo, ConsultationCRepo>();
builder.Services.AddScoped<IVaccinationCRepo, VaccinationCRepo>();
builder.Services.AddScoped<IClientProfileRepo, ClientProfileRepo>();
builder.Services.AddScoped<IVetCRepo, VetCRepo>();


//add Veterinaire Repositories
builder.Services.AddScoped<IAnimalVRepo, AnimalVRepo>();
builder.Services.AddScoped<IRendezVousVRepo, RendezVousVRepo>();
builder.Services.AddScoped<IConsultationVetRepo, ConsultationVetRepo>();
builder.Services.AddScoped<IVaccinationVetRepo, VaccinationVetRepo>();
builder.Services.AddScoped<IVeterinaireProfileRepo, VeterinaireProfileRepo>();
builder.Services.AddScoped<IClientVetRepo, ClientVetRepo>();
builder.Services.AddScoped<IProductVetRepo, ProductVetRepo>();



// Add PostgreSQL DB connection
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PostgresConnection")));

// Configure Identity
builder.Services.AddIdentity<AppUser, ApplicationRole>(options =>
{
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = false;
    options.Tokens.PasswordResetTokenProvider = TokenOptions.DefaultEmailProvider;
    options.Tokens.EmailConfirmationTokenProvider = TokenOptions.DefaultEmailProvider;
    options.SignIn.RequireConfirmedAccount = true;
    options.Tokens.AuthenticatorTokenProvider = TokenOptions.DefaultAuthenticatorProvider;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

builder.Services.Configure<IdentityOptions>(options =>
{
    options.SignIn.RequireConfirmedEmail = true;
});


builder.Services.AddSignalR(options => {
    options.EnableDetailedErrors = true;
}).AddJsonProtocol(options => {
    options.PayloadSerializerOptions.PropertyNamingPolicy = null; 
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"],
        ValidAudience = jwtSettings["ValidAudience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings["SecretKey"]))
    };
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;

            // Case-insensitive path check
            if (!string.IsNullOrEmpty(accessToken) &&
                (path.StartsWithSegments("/chatHub", StringComparison.OrdinalIgnoreCase) ||
                 path.StartsWithSegments("/webrtchub", StringComparison.OrdinalIgnoreCase)))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };

});


//add authorization with role
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Admin", policy => policy.RequireRole("Admin"));
    options.AddPolicy("Client", policy => policy.RequireRole("Client"));
    options.AddPolicy("Veterinaire", policy => policy.RequireRole("Veterinaire"));
    options.AddPolicy("ClientOrVeterinaire", policy =>
       policy.RequireAssertion(context =>
           context.User.IsInRole("Client") || context.User.IsInRole("Veterinaire")));

});

builder.Services.Configure<Microsoft.AspNetCore.Builder.WebSocketOptions>(options =>
{
    options.KeepAliveInterval = TimeSpan.FromSeconds(5);  
});
// Add to builder setup
builder.Logging.AddConsole().SetMinimumLevel(LogLevel.Debug);
builder.Services.AddSignalR(options => {
    options.EnableDetailedErrors = true;
});

// For Kestrel (if using)
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(5);
});

builder.Services.AddSingleton<IUserIdProvider, GuidUserIdProvider>();

builder.Logging.AddFilter("Microsoft.AspNetCore.Http.Connections", LogLevel.Trace);
builder.Logging.AddFilter("Microsoft.AspNetCore.SignalR", LogLevel.Trace);

var app = builder.Build();




// Enable CORS globally

//app.UseHttpsRedirection();
app.UseRouting();
app.UseCors("AllowAll");


app.UseAuthentication();  // Authentication middleware comes first
app.UseAuthorization();   // Authorization middleware should come after authentication

app.MapHub<ChatHub>("/chatHub");  // Must match your URL path
app.MapHub<WebRTCHub>("/rtchub");


app.MapControllers();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseStaticFiles();


app.Run();
