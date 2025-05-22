using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class changeRdvIdToClientIdInConsultation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Consultations_Animals_AnimalId",
                table: "Consultations");

            migrationBuilder.RenameColumn(
                name: "AnimalId",
                table: "Consultations",
                newName: "ClientId");

            migrationBuilder.RenameIndex(
                name: "IX_Consultations_AnimalId",
                table: "Consultations",
                newName: "IX_Consultations_ClientId");

            migrationBuilder.AddForeignKey(
                name: "FK_Consultations_clients_ClientId",
                table: "Consultations",
                column: "ClientId",
                principalTable: "clients",
                principalColumn: "ClientId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Consultations_clients_ClientId",
                table: "Consultations");

            migrationBuilder.RenameColumn(
                name: "ClientId",
                table: "Consultations",
                newName: "AnimalId");

            migrationBuilder.RenameIndex(
                name: "IX_Consultations_ClientId",
                table: "Consultations",
                newName: "IX_Consultations_AnimalId");

            migrationBuilder.AddForeignKey(
                name: "FK_Consultations_Animals_AnimalId",
                table: "Consultations",
                column: "AnimalId",
                principalTable: "Animals",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
