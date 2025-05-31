using Microsoft.AspNetCore.Mvc;

using Microsoft.AspNetCore.Authorization;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting; // For IWebHostEnvironment
using System;

namespace backend.Controllers.TelecommunicationControllers
{
    [ApiController]
    [Route("api/[controller]")] // e.g., /api/files
    [Authorize] // Ensure only authenticated users can upload
    public class FilesController : ControllerBase
    {
        private readonly IWebHostEnvironment _hostingEnvironment;

        public FilesController(IWebHostEnvironment hostingEnvironment)
        {
            _hostingEnvironment = hostingEnvironment;
        }

        [HttpPost("upload")] // e.g., /api/files/upload
        public async Task<IActionResult> UploadFile([FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file uploaded." });
            }

            // Define the path to the uploads folder within wwwroot
            var uploadsFolder = Path.Combine(_hostingEnvironment.WebRootPath, "uploads");

            // Create the directory if it doesn't exist
            if (!Directory.Exists(uploadsFolder))
            {
                Directory.CreateDirectory(uploadsFolder);
            }

            // Generate a unique filename to prevent overwrites and security issues
            var uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetFileName(file.FileName);
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Construct the URL to access the file.
            // This assumes your API is served from the root and wwwroot is accessible.
            var fileUrl = $"/uploads/{uniqueFileName}";

            return Ok(new { fileUrl = fileUrl, fileName = file.FileName, message = "File uploaded successfully." });
        }
    }
}