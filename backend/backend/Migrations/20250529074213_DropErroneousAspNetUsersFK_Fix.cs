using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations // Ensure this namespace matches your project's Migrations namespace
{
    public partial class DropErroneousAspNetUsersFK_Fix : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // SQL to drop the problematic foreign key constraint.
            // This is the FK that's causing conflict with your intended Veterinaire link.
            migrationBuilder.Sql(
                @"ALTER TABLE ""Consultations"" DROP CONSTRAINT ""FK_Consultations_AspNetUsers_VeterinaireId"";"
            );
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // In the Down method, you should ideally add the constraint back for rollback purposes.
            // This re-creates the constraint you just dropped.
            // Ensure "VeterinaireId" is the correct column name in Consultations.
            migrationBuilder.Sql(
                @"ALTER TABLE ""Consultations"" ADD CONSTRAINT ""FK_Consultations_AspNetUsers_VeterinaireId""
                  FOREIGN KEY (""VeterinaireId"") REFERENCES ""AspNetUsers"" (""Id"") ON DELETE RESTRICT;" // Adjust ON DELETE as per your desired behavior
            );
        }
    }
}