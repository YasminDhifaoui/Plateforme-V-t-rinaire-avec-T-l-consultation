using backend.Models;

public class ApplicationUserRole
{
    public Guid UserId { get; set; }
    public AppUser User { get; set; } 

    public string RoleId { get; set; }
    public ApplicationRole Role { get; set; }  
}
