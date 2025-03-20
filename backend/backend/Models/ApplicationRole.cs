using Microsoft.AspNetCore.Identity;
using System;

public class ApplicationRole : IdentityRole<Guid>
{
    public const string Admin = "Admin";
    public const string Client = "Client";
    public const string Veterinaire = "Veterinaire";

    public ApplicationRole() : base() { }

    public ApplicationRole(string roleName) : base(roleName) { }
}
